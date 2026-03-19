# User Management

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## Overview

loxilb-enterprise provides built-in user management with authentication, role-based access control (RBAC), and API key management. This enables enterprise teams to control who can access and modify the gateway configuration without relying on external identity infrastructure.

Three authentication modes are available — **DB-based JWT** (for internal users with MySQL backend), **OAuth2** (for SSO with Google or GitHub), and **manual token** (for CI/CD automation). These modes are mutually exclusive and selected at loxilb startup time.

## Auth Mode Selection

| Auth Mode | CLI Flag | Mechanism | Use Case |
|-----------|----------|-----------|----------|
| DB-based JWT | `--userservice` | PBKDF2+SHA256 password hash, JWT HS256 token, 24h TTL | Internal enterprise users |
| OAuth2 | `--oauth2 --oauth2provider=google\|github` | Google/GitHub OAuth2 flow | SSO with corporate IdP |
| Manual token | `--manualtoken` | File-based static token | Automation/CI pipelines |

!!! warning "Mutually Exclusive"
    These auth modes use an if/else chain in `BearerAuthAuth()`. Do **NOT** combine `--userservice` with `--oauth2` in the same deployment. Only one auth mode can be active at a time.

    Source: `api/restapi/handler/auth.go:96-122`

## DB-Based JWT Authentication

The DB-based JWT mode provides full user lifecycle management backed by a MySQL database.

### Prerequisites

- MySQL database server running and accessible
- Database and user created for loxilb

### Startup Configuration

```bash
# Source: options/options.go:50-55
loxilb --userservice \
  --databasehost=127.0.0.1 \
  --databaseport=3306 \
  --databaseuser=loxilb \
  --databasepasswordpath=/etc/loxilb/mysql_password \
  --databasename=loxilb_db
```

### Database Schema

loxilb auto-creates the following tables on first startup:

| Table | Key Columns | Purpose |
|-------|-------------|---------|
| `users` | id, username, password, created_at, role | User accounts with hashed passwords |
| `token` | token_value, username, expires_at, role | Active JWT sessions |
| `api_keys` | key_hash, username, created_at | API key SHA-256 hashes |
| `tenant_rate_limits` | tenant, requests_per_min | Per-tenant rate limits |

Source: `pkg/db/db.go:81-87`

### Login Flow

```bash
# Source: api/restapi/handler/auth.go:64-80
# Step 1: Login and get JWT token
curl -X POST http://loxilb:11111/netlox/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "Admin@1234"}'
# Response: {"token": "eyJ..."}

# Step 2: Use token in subsequent requests
curl http://loxilb:11111/netlox/v1/config/loadbalancer/all \
  -H "Authorization: Bearer eyJ..."
```

**Token details:** JWT HS256, 24-hour expiry (`TokenExpirationMinutes=1440`). Tokens are stored in the `token` database table and can be invalidated via the logout endpoint.

## OAuth2 Authentication

OAuth2 mode integrates with Google or GitHub for single sign-on.

### Startup Configuration

```bash
# Google SSO
loxilb --oauth2 --oauth2provider=google
# Required environment variables:
# OAUTH2_GOOGLE_CLIENT_ID
# OAUTH2_GOOGLE_CLIENT_SECRET
# OAUTH2_GOOGLE_REDIRECT_URL

# GitHub SSO
loxilb --oauth2 --oauth2provider=github
# Required environment variables:
# OAUTH2_GITHUB_CLIENT_ID
# OAUTH2_GITHUB_CLIENT_SECRET
# OAUTH2_GITHUB_REDIRECT_URL
```

!!! warning "Token Persistence"
    OAuth2 tokens are stored in `/opt/loxilb/oauth_tokens.json`. In Docker or Kubernetes deployments, mount `/opt/loxilb/` as a **persistent volume** to prevent session loss on container restart.

    Source: `pkg/user/oauth_user.go`

### Docker Volume Mount Example

```yaml
# docker-compose.yml
services:
  loxilb:
    image: ghcr.io/netlox-dev/loxilb-enterprise:latest
    command: --oauth2 --oauth2provider=google
    volumes:
      - loxilb-data:/opt/loxilb
    environment:
      - OAUTH2_GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
      - OAUTH2_GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
      - OAUTH2_GOOGLE_REDIRECT_URL=${GOOGLE_REDIRECT_URL}

volumes:
  loxilb-data:
```

## Manual Token Authentication

Manual token mode uses a static token read from a file at startup — ideal for CI/CD pipelines and automation scripts.

```bash
# Source: options/options.go
loxilb --manualtoken --manualtokenvalue=/etc/loxilb/manual_token
```

- The token file contains a single token string
- Include in requests as `Authorization: Bearer <token-value>`
- No user management features (no login/logout, no RBAC roles)
- Token does not expire — rotate by updating the file and restarting loxilb

## RBAC (Role-Based Access Control)

Two roles control what authenticated users can do:

| Role | Permissions | Restrictions |
|------|------------|--------------|
| `admin` | Full read/write access | No restrictions |
| `viewer` | Read-only (GET requests only) | All POST/PUT/DELETE blocked except `/netlox/v1/auth/logout` |

Source: `auth.go:110` — `strings.Contains(UserRole, "viewer") && param.Method != "GET"` returns "Permission denied"

### Creating Users with Roles

```bash
# Source: api/restapi/handler/auth.go
# Create a viewer user
curl -X POST http://loxilb:11111/netlox/v1/config/user \
  -H "Authorization: Bearer <admin-token>" \
  -H "Content-Type: application/json" \
  -d '{"username": "ops-user", "password": "Ops@12345", "role": "viewer"}'

# List all users
curl http://loxilb:11111/netlox/v1/config/user/all \
  -H "Authorization: Bearer <admin-token>"

# Delete a user
curl -X DELETE http://loxilb:11111/netlox/v1/config/user/ops-user \
  -H "Authorization: Bearer <admin-token>"

# Update a user
curl -X PUT http://loxilb:11111/netlox/v1/config/user/ops-user \
  -H "Authorization: Bearer <admin-token>" \
  -H "Content-Type: application/json" \
  -d '{"role": "admin"}'
```

## Password Policy

All passwords must satisfy these rules:

| Rule | Description |
|------|-------------|
| Minimum length | At least 9 characters |
| Uppercase letter | At least one uppercase letter (A-Z) |
| Lowercase letter | At least one lowercase letter (a-z) |
| Digit | At least one digit (0-9) |
| Special character | At least one special character |
| No consecutive repeats | No more than 3 consecutive identical characters |
| Not username | Password cannot be the same as the username |
| Not previous password | Password cannot be the same as the previous password |

Source: `pkg/user/user_util.go:validatePassword()`

Passwords that fail validation return a descriptive error message indicating which rule was violated.

## API Key Management

API keys provide an alternative to JWT tokens for programmatic access. Keys are long-lived and suitable for service-to-service authentication.

```bash
# Source: pkg/user/api_key.go
# Create API key (returns key with lxb_ prefix)
curl -X POST http://loxilb:11111/netlox/v1/config/apikey \
  -H "Authorization: Bearer <admin-token>"
# Response: {"api_key": "lxb_abc123..."}

# Use API key in requests (X-API-Key header)
curl http://loxilb:11111/netlox/v1/config/loadbalancer/all \
  -H "X-API-Key: lxb_abc123..."

# Revoke API key
curl -X DELETE http://loxilb:11111/netlox/v1/config/apikey/lxb_abc123 \
  -H "Authorization: Bearer <admin-token>"
```

- API keys use the `lxb_` prefix for identification
- Keys are stored as **SHA-256 hashes** in the database — the plaintext key is only shown once at creation
- Keys inherit the role of the user who created them

## Per-Tenant Rate Limiting

Rate limits can be set per tenant to control API usage:

```bash
# Set rate limit for a tenant
curl -X POST http://loxilb:11111/netlox/v1/config/tenant/ratelimit \
  -H "Authorization: Bearer <admin-token>" \
  -H "Content-Type: application/json" \
  -d '{"tenant": "customer-a", "requests_per_min": 1000}'
```

Rate limits are enforced per-tenant across all API keys belonging to that tenant.

## REST API Endpoints Summary

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/netlox/v1/auth/login` | POST | Login and get JWT token |
| `/netlox/v1/auth/logout` | POST | Logout (invalidate token) |
| `/netlox/v1/config/user` | POST | Create user |
| `/netlox/v1/config/user/all` | GET | List all users |
| `/netlox/v1/config/user/{name}` | DELETE | Delete user |
| `/netlox/v1/config/user/{name}` | PUT | Update user |
| `/netlox/v1/config/apikey` | POST | Create API key |
| `/netlox/v1/config/apikey/{key}` | DELETE | Revoke API key |
| `/netlox/v1/config/tenant/ratelimit` | POST | Set tenant rate limit |

## See Also

- [Monitoring Setup](monitoring.md) — Prometheus metrics and Grafana dashboards for enterprise monitoring
- [Network Gateway Overview](../network-gateway/overview.md) — Network Gateway features overview
