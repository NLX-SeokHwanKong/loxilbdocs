# Enterprise API Reference

!!! enterprise "Enterprise Feature"
    This reference covers enterprise-only API endpoints not available in the community edition.
    For community endpoints, see the [Community API Reference](https://app.swaggerhub.com/apis-docs/ADMIN_111/loxilb/1.0.0).

## Overview

The loxilb-enterprise REST API is served at:

```
http(s)://<host>:11111/netlox/v1
```

All request and response bodies use `Content-Type: application/json`. The API follows standard HTTP response codes:

| Code | Meaning |
|------|---------|
| 200 | Success with response body |
| 201 | Created with response body |
| 204 | Success, no content |
| 400 | Bad request — malformed input |
| 401 | Unauthorized — missing or invalid token |
| 403 | Forbidden — insufficient permissions |
| 404 | Not found |
| 500 | Internal server error |

Error responses use the `Error` schema:

```json
{"error": "descriptive error message"}
```

Authentication is required on **all endpoints** except:

- `POST /auth/login` — authenticate and obtain JWT
- `POST /auth/users` — create new user (open registration)
- `GET /meta` — API metadata

All authenticated requests must include the JWT token in the `Authorization` header:

```
Authorization: Bearer <token>
```

## Authentication Flow

The authentication flow is the entry point for all enterprise API usage. Obtain a JWT token first, then use it for all subsequent requests.

```mermaid
sequenceDiagram
    participant Client
    participant API as loxilb API
    Client->>API: POST /auth/login {username, password}
    API-->>Client: {token: "eyJ..."}
    Client->>API: GET /auth/users<br/>Authorization: Bearer eyJ...
    API-->>Client: [{id, username, role}]
```

=== "Login (Local Auth)"

    ```bash
    # Source: api/swagger.yml — POST /auth/login
    curl -X POST http://localhost:11111/netlox/v1/auth/login \
      -H "Content-Type: application/json" \
      -d '{"username": "admin", "password": "admin"}'

    # Response (200):
    # {"token": "eyJhbGciOiJIUzI1NiIs..."}
    ```

=== "Login (OAuth2 — Google)"

    ```bash
    # Source: api/swagger.yml — GET /oauth/{provider}
    # Step 1: Initiate OAuth flow
    curl http://localhost:11111/netlox/v1/oauth/google

    # Step 2: After callback, retrieve token
    curl http://localhost:11111/netlox/v1/oauth/google/token?token=ACCESS&refreshtoken=REFRESH
    ```

=== "Using the Token"

    ```bash
    # All subsequent requests include the Bearer token
    curl http://localhost:11111/netlox/v1/auth/users \
      -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
    ```

!!! tip "Token Storage"
    The `loxicmd` CLI stores tokens at `/tmp/loxilbtoken` after `loxicmd set login`. See the [CLI Reference](cli.md) for command-line authentication workflows.

For detailed authentication configuration (DB-based JWT, OAuth2, manual token), see [User Management](../operations/user-management.md).

## User Management Endpoints

!!! enterprise "Enterprise Feature"
    User management endpoints are enterprise-only additions to the loxilb API.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/auth/login` | Authenticate and get JWT token | No |
| POST | `/auth/logout` | Invalidate current token | Yes |
| POST | `/auth/token/upgrade` | Upgrade manual license token | Yes |
| GET | `/auth/users` | List all users | Yes |
| POST | `/auth/users` | Create new user | No |
| PUT | `/auth/users/{id}` | Update user by ID | Yes |
| DELETE | `/auth/users/{id}` | Delete user by ID | Yes |
| GET | `/oauth/{provider}` | Initiate OAuth2 flow | No |
| GET | `/oauth/{provider}/callback` | OAuth2 callback handler | No |
| GET | `/oauth/{provider}/token` | Retrieve OAuth2 token | No |

### Create User

```bash
# Source: api/swagger.yml — POST /auth/users
curl -X POST http://localhost:11111/netlox/v1/auth/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "operator",
    "password": "securePass123",
    "role": "user"
  }'

# Response (201):
# {
#   "id": 2,
#   "username": "operator",
#   "role": "user"
# }
```

**Request Body — `User`:**

| Field | Type | Required | Description |
|-------|------|:---:|-------------|
| `username` | string | Yes | Unique username |
| `password` | string | Yes | User password (hashed server-side with PBKDF2+SHA256) |
| `role` | string | Yes | `"admin"` or `"user"` |

### Update User

```bash
# Source: api/swagger.yml — PUT /auth/users/{id}
curl -X PUT http://localhost:11111/netlox/v1/auth/users/2 \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{"username": "operator", "password": "newPass456", "role": "admin"}'

# Response (200):
# {"id": 2, "username": "operator", "role": "admin"}
```

### Token Upgrade

```bash
# Source: api/swagger.yml — POST /auth/token/upgrade
curl -X POST http://localhost:11111/netlox/v1/auth/token/upgrade \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{"token": "new-license-token-string"}'

# Response (200): Updated token
```

## AI Gateway — API Key Management

!!! enterprise "Enterprise Feature"
    AI Gateway API key management is an enterprise-only feature for controlling access to LLM routing.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/ai/apikey` | Create API key | Yes |
| GET | `/config/ai/apikey` | List all API keys | Yes |
| GET | `/config/ai/apikey/{key_id}` | Get specific API key | Yes |
| DELETE | `/config/ai/apikey/{key_id}` | Delete API key | Yes |

### Create API Key

```bash
# Source: api/swagger.yml — POST /config/ai/apikey
curl -X POST http://localhost:11111/netlox/v1/config/ai/apikey \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "acme-corp",
    "name": "production-key",
    "allowed_models": ["gpt-4", "claude-3"],
    "rate_limit_rps": 100,
    "burst_size": 200,
    "tokens_per_min": 50000,
    "expires_at": "2025-12-31T23:59:59Z"
  }'

# Response (201):
# {
#   "key_id": "ak_abc123def456",
#   "raw_key": "lxk_live_a1b2c3d4e5f6..."
# }
```

!!! warning "Save the Raw Key"
    The `raw_key` is shown **only once** in the create response. Store it securely — it cannot be retrieved later.

**Request Body — `ApiKeyCreateRequest`:**

| Field | Type | Required | Description |
|-------|------|:---:|-------------|
| `tenant_id` | string | Yes | Tenant identifier for multi-tenant isolation |
| `name` | string | No | Human-readable key name |
| `allowed_models` | string[] | No | List of permitted model names |
| `rate_limit_rps` | integer | No | Maximum requests per second |
| `burst_size` | integer | No | Burst allowance above rate limit |
| `tokens_per_min` | integer | No | Token quota per minute |
| `expires_at` | string | No | Expiration time (RFC 3339 format) |

### List API Keys

```bash
# Source: api/swagger.yml — GET /config/ai/apikey
# List all keys (optionally filter by tenant)
curl http://localhost:11111/netlox/v1/config/ai/apikey?tenant_id=acme-corp \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# [
#   {
#     "key_id": "ak_abc123def456",
#     "tenant_id": "acme-corp",
#     "name": "production-key",
#     "allowed_models": ["gpt-4", "claude-3"],
#     "rate_limit_rps": 100,
#     "burst_size": 200,
#     "tokens_per_min": 50000,
#     "enabled": true,
#     "expires_at": "2025-12-31T23:59:59Z"
#   }
# ]
```

## AI Gateway — Tenant Rate Limits

!!! enterprise "Enterprise Feature"
    Per-tenant rate limiting for AI Gateway traffic is enterprise-only.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/ai/tenant/ratelimit` | Create or update tenant rate limit | Yes |
| GET | `/config/ai/tenant/ratelimit/{tenant_id}` | Get tenant rate limit | Yes |

### Create Tenant Rate Limit

```bash
# Source: api/swagger.yml — POST /config/ai/tenant/ratelimit
curl -X POST http://localhost:11111/netlox/v1/config/ai/tenant/ratelimit \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "acme-corp",
    "rps": 200,
    "tokens_per_min": 100000
  }'

# Response (204): No content — upsert applied
```

**Request Body — `TenantRateLimitMod`:**

| Field | Type | Required | Description |
|-------|------|:---:|-------------|
| `tenant_id` | string | Yes | Tenant identifier |
| `rps` | integer | No | Requests per second limit |
| `tokens_per_min` | integer | No | Token quota per minute |

### Get Tenant Rate Limit

```bash
# Source: api/swagger.yml — GET /config/ai/tenant/ratelimit/{tenant_id}
curl http://localhost:11111/netlox/v1/config/ai/tenant/ratelimit/acme-corp \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# {
#   "tenant_id": "acme-corp",
#   "rps": 200,
#   "tokens_per_min": 100000,
#   "updated_at": "2025-01-15T10:30:00Z"
# }
```

## AI Gateway — GPU and LLM Catalog

!!! enterprise "Enterprise Feature"
    GPU-aware load balancing and LLM catalog management are enterprise-only features.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/gpu/enable` | Enable GPU-aware load balancing | Yes |
| POST | `/config/gpu/disable` | Disable GPU-aware load balancing | Yes |
| GET | `/config/gpu/status` | Get GPU feature status | Yes |
| POST | `/config/gpu/conversations/cleanup` | Clean up orphaned conversation state | Yes |
| GET | `/config/llm-catalogs` | List all LLM catalog profiles | Yes |
| GET | `/config/llm-catalogs/{catalogName}` | Get specific LLM catalog | Yes |

### List LLM Catalogs

```bash
# Source: api/swagger.yml — GET /config/llm-catalogs
curl http://localhost:11111/netlox/v1/config/llm-catalogs \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# [
#   {
#     "name": "gpt-4-turbo",
#     "model_type": "chat",
#     "provider": "openai",
#     "context_window": 128000,
#     "max_output_tokens": 4096
#   }
# ]
```

### Enable GPU-Aware Load Balancing

```bash
# Source: api/swagger.yml — POST /config/gpu/enable
curl -X POST http://localhost:11111/netlox/v1/config/gpu/enable \
  -H "Authorization: Bearer eyJhbG..."

# Response (200): {"result": "Success"}
```

## OPA Policy Watcher

!!! enterprise "Enterprise Feature"
    OPA (Open Policy Agent) integration for L4 policy enforcement is enterprise-only.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/opa/watcher` | Configure and start OPA watcher | Yes |
| GET | `/config/opa/watcher` | Get OPA watcher status | Yes |
| DELETE | `/config/opa/watcher` | Stop and remove OPA watcher | Yes |

### Configure OPA Watcher

```bash
# Source: api/swagger.yml — POST /config/opa/watcher
curl -X POST http://localhost:11111/netlox/v1/config/opa/watcher \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "opa_url": "http://opa-server:8181",
    "policy_path": "loxilb/l4",
    "poll_interval_sec": 30,
    "fail_open": true
  }'

# Response (200): {"result": "Success"}
```

**Request Body — `OPAWatcherConfig`:**

| Field | Type | Required | Description |
|-------|------|:---:|-------------|
| `opa_url` | string | Yes | OPA server URL |
| `policy_path` | string | No | Rego policy path (default: `loxilb/l4`) |
| `poll_interval_sec` | integer | No | Policy poll interval in seconds (default: 30) |
| `fail_open` | boolean | No | Allow traffic when OPA is unreachable (default: false) |

### Get OPA Watcher Status

```bash
# Source: api/swagger.yml — GET /config/opa/watcher
curl http://localhost:11111/netlox/v1/config/opa/watcher \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# {
#   "opa_url": "http://opa-server:8181",
#   "policy_path": "loxilb/l4",
#   "poll_interval_sec": 30,
#   "fail_open": true,
#   "status": "running",
#   "last_poll": "2025-01-15T10:30:00Z"
# }
```

## PII Detection (Presidio)

!!! enterprise "Enterprise Feature"
    Presidio-based PII detection for AI traffic is enterprise-only.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/pii/enable` | Enable PII detection | Yes |
| POST | `/config/pii/configure` | Configure PII detection settings | Yes |
| POST | `/config/pii/url-patterns` | Set URL patterns for PII scanning | Yes |
| GET | `/config/pii/status` | Get PII detection status | Yes |
| GET | `/config/pii/stats` | Get PII detection statistics | Yes |

### Enable PII Detection

```bash
# Source: api/swagger.yml — POST /config/pii/enable
curl -X POST http://localhost:11111/netlox/v1/config/pii/enable \
  -H "Authorization: Bearer eyJhbG..."

# Response (200): {"result": "Success"}
```

### Configure PII Detection

```bash
# Source: api/swagger.yml — POST /config/pii/configure
curl -X POST http://localhost:11111/netlox/v1/config/pii/configure \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "presidio_url": "http://presidio-analyzer:5002",
    "score_threshold": 0.7,
    "entities": ["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER", "CREDIT_CARD"],
    "action": "redact"
  }'

# Response (200): {"result": "Success"}
```

### Get PII Status

```bash
# Source: api/swagger.yml — GET /config/pii/status
curl http://localhost:11111/netlox/v1/config/pii/status \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# {
#   "enabled": true,
#   "presidio_url": "http://presidio-analyzer:5002",
#   "score_threshold": 0.7,
#   "entities": ["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER", "CREDIT_CARD"],
#   "action": "redact"
# }
```

## LlamaFirewall

!!! enterprise "Enterprise Feature"
    LlamaFirewall integration for AI content safety is enterprise-only.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/llamafirewall/enable` | Enable LlamaFirewall | Yes |
| POST | `/config/llamafirewall/configure` | Configure LlamaFirewall settings | Yes |
| POST | `/config/llamafirewall/scanners` | Configure scanners | Yes |
| POST | `/config/llamafirewall/health` | Trigger health check | Yes |
| GET | `/config/llamafirewall/status` | Get status and enabled scanners | Yes |
| GET | `/config/llamafirewall/stats` | Get scanning statistics | Yes |

### Enable LlamaFirewall

```bash
# Source: api/swagger.yml — POST /config/llamafirewall/enable
curl -X POST http://localhost:11111/netlox/v1/config/llamafirewall/enable \
  -H "Authorization: Bearer eyJhbG..."

# Response (200): {"result": "Success"}
```

### Configure Scanners

```bash
# Source: api/swagger.yml — POST /config/llamafirewall/scanners
curl -X POST http://localhost:11111/netlox/v1/config/llamafirewall/scanners \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "scanners": [
      {"name": "prompt-injection", "enabled": true, "threshold": 0.8},
      {"name": "content-filter", "enabled": true, "categories": ["violence", "hate"]}
    ]
  }'

# Response (200): {"result": "Success"}
```

### Get LlamaFirewall Status

```bash
# Source: api/swagger.yml — GET /config/llamafirewall/status
curl http://localhost:11111/netlox/v1/config/llamafirewall/status \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# {
#   "enabled": true,
#   "scanners": [
#     {"name": "prompt-injection", "enabled": true, "threshold": 0.8},
#     {"name": "content-filter", "enabled": true}
#   ],
#   "health": "healthy"
# }
```

### Get Scanning Statistics

```bash
# Source: api/swagger.yml — GET /config/llamafirewall/stats
curl http://localhost:11111/netlox/v1/config/llamafirewall/stats \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# {
#   "total_scanned": 15420,
#   "blocked": 23,
#   "passed": 15397,
#   "by_scanner": {
#     "prompt-injection": {"scanned": 15420, "blocked": 12},
#     "content-filter": {"scanned": 15420, "blocked": 11}
#   }
# }
```

## L4 Connection Tracing

!!! enterprise "Enterprise Feature"
    L4 connection tracing with eBPF-level visibility is enterprise-only.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/l4trace/enable` | Enable L4 tracing with sampling rate | Yes |
| POST | `/config/l4trace/disable` | Disable L4 tracing | Yes |
| GET | `/config/l4trace/status` | Get tracing status and statistics | Yes |
| PUT | `/config/l4trace/sampling` | Update sampling rate | Yes |
| POST | `/config/l4trace/stats/reset` | Reset tracing statistics | Yes |

### Enable L4 Tracing

```bash
# Source: api/swagger.yml — POST /config/l4trace/enable
curl -X POST http://localhost:11111/netlox/v1/config/l4trace/enable \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{"sampling_rate": 50}'

# Response (200): {"result": "Success"}
```

### Get Tracing Status

```bash
# Source: api/swagger.yml — GET /config/l4trace/status
curl http://localhost:11111/netlox/v1/config/l4trace/status \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# {
#   "enabled": true,
#   "sampling_rate": 50,
#   "config_version": 3,
#   "stats": {
#     "total_events": 1542000,
#     "sampled_events": 771000,
#     "dropped_events": 0,
#     "tcp_events": 650000,
#     "sctp_events": 12000,
#     "udp_events": 109000,
#     "conn_new": 250000,
#     "conn_established": 245000,
#     "conn_closed": 240000,
#     "conn_timeout": 3000,
#     "conn_reset": 1500,
#     "conn_error": 500
#   }
# }
```

**Response — `L4TraceStatusResponse`:**

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | boolean | Whether L4 tracing is active |
| `sampling_rate` | integer | Current sampling rate (0–100%) |
| `config_version` | integer | Configuration version counter |
| `stats.total_events` | integer | Total connection events observed |
| `stats.sampled_events` | integer | Events captured at current sampling rate |
| `stats.dropped_events` | integer | Events dropped due to buffer overflow |
| `stats.tcp_events` | integer | TCP connection events |
| `stats.sctp_events` | integer | SCTP connection events |
| `stats.udp_events` | integer | UDP connection events |
| `stats.conn_new` | integer | New connection events |
| `stats.conn_established` | integer | Established connection events |
| `stats.conn_closed` | integer | Closed connection events |
| `stats.conn_timeout` | integer | Timed out connections |
| `stats.conn_reset` | integer | Reset connections |
| `stats.conn_error` | integer | Connection errors |

### Update Sampling Rate

```bash
# Source: api/swagger.yml — PUT /config/l4trace/sampling
curl -X PUT http://localhost:11111/netlox/v1/config/l4trace/sampling \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{"sampling_rate": 25}'

# Response (200): {"result": "Success"}
```

## Distributed Tracing (OTLP)

!!! enterprise "Enterprise Feature"
    OpenTelemetry-based distributed tracing is enterprise-only.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/trace/enable` | Enable distributed tracing | Yes |
| POST | `/config/trace/disable` | Disable distributed tracing | Yes |
| GET | `/config/trace/status` | Get tracing status | Yes |
| POST | `/config/trace/otlp` | Configure OTLP exporter | Yes |
| GET | `/config/trace/otlp` | Get OTLP configuration | Yes |
| GET | `/config/trace/catalogs` | List trace catalog entries | Yes |
| GET | `/config/trace/parsers` | List configured parsers | Yes |
| GET | `/config/trace/catalog/{catalog_id}/parser` | Get parser for catalog | Yes |
| PUT | `/config/trace/catalog/{catalog_id}/parser` | Update parser for catalog | Yes |
| DELETE | `/config/trace/catalog/{catalog_id}/parser` | Remove parser for catalog | Yes |

### Enable Tracing and Configure OTLP

```bash
# Source: api/swagger.yml — POST /config/trace/enable
curl -X POST http://localhost:11111/netlox/v1/config/trace/enable \
  -H "Authorization: Bearer eyJhbG..."

# Response (200): {"result": "Success"}
```

```bash
# Source: api/swagger.yml — POST /config/trace/otlp
curl -X POST http://localhost:11111/netlox/v1/config/trace/otlp \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "endpoint": "http://jaeger:4318",
    "protocol": "http",
    "service_name": "loxilb-gateway",
    "batch_size": 512,
    "export_interval_ms": 5000
  }'

# Response (200): {"result": "Success"}
```

### List Trace Catalogs

```bash
# Source: api/swagger.yml — GET /config/trace/catalogs
curl http://localhost:11111/netlox/v1/config/trace/catalogs \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# [
#   {
#     "catalog_id": "http-lb",
#     "description": "HTTP load balancer traces",
#     "parser": "http-parser"
#   }
# ]
```

## IPsec

!!! enterprise "Enterprise Feature"
    IPsec secure dataplane is enterprise-only, providing encrypted tunnel and transport mode connectivity.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| GET | `/config/ipsec` | Get global IPsec configuration | Yes |
| POST | `/config/ipsec` | Configure IPsec global settings | Yes |
| POST | `/config/ipsec/tunnels` | Create IPsec tunnel | Yes |
| GET | `/config/ipsec/tunnels/all` | List all tunnels | Yes |
| GET | `/config/ipsec/tunnels/{name}` | Get specific tunnel | Yes |
| DELETE | `/config/ipsec/tunnels/{name}` | Delete tunnel | Yes |
| GET | `/config/ipsec/sas/all` | List Security Associations | Yes |
| GET | `/config/ipsec/stats` | Get IPsec statistics | Yes |
| DELETE | `/config/ipsec/stats` | Clear IPsec statistics | Yes |
| POST | `/config/ipsec/certificates` | Upload certificate | Yes |
| GET | `/config/ipsec/certificates/all` | List certificates | Yes |
| GET | `/config/ipsec/certificates/{name}` | Get specific certificate | Yes |
| DELETE | `/config/ipsec/certificates/{name}` | Delete certificate | Yes |
| POST | `/config/ipsec/certificates/validate` | Validate certificate | Yes |
| POST | `/config/ipsec/ca-certificates` | Upload CA certificate | Yes |
| GET | `/config/ipsec/ca-certificates/all` | List CA certificates | Yes |
| GET | `/config/ipsec/ca-certificates/{name}` | Get CA certificate | Yes |
| DELETE | `/config/ipsec/ca-certificates/{name}` | Delete CA certificate | Yes |

### Create IPsec Tunnel

```bash
# Source: api/swagger.yml — POST /config/ipsec/tunnels
curl -X POST http://localhost:11111/netlox/v1/config/ipsec/tunnels \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "site-to-site-1",
    "local_ip": "10.0.1.1",
    "remote_ip": "10.0.2.1",
    "local_subnet": "192.168.1.0/24",
    "remote_subnet": "192.168.2.0/24",
    "auth_method": "psk",
    "psk": "shared-secret-key",
    "ike_version": 2,
    "encryption": "aes256",
    "integrity": "sha256"
  }'

# Response (201): Tunnel created
```

### List Tunnels

```bash
# Source: api/swagger.yml — GET /config/ipsec/tunnels/all
curl http://localhost:11111/netlox/v1/config/ipsec/tunnels/all \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# [
#   {
#     "name": "site-to-site-1",
#     "local_ip": "10.0.1.1",
#     "remote_ip": "10.0.2.1",
#     "status": "established",
#     "bytes_in": 1048576,
#     "bytes_out": 2097152
#   }
# ]
```

### Upload Certificate

```bash
# Source: api/swagger.yml — POST /config/ipsec/certificates
curl -X POST http://localhost:11111/netlox/v1/config/ipsec/certificates \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "gateway-cert",
    "certificate": "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----"
  }'

# Response (201): Certificate uploaded
```

## Security Controls

!!! enterprise "Enterprise Feature"
    Advanced security controls including SYN flood protection, rate limiting, and IP filtering are enterprise-extended features.

### SYN Flood Protection

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/synflood` | Configure SYN flood protection | Yes |
| DELETE | `/config/synflood` | Remove SYN flood protection | Yes |
| GET | `/config/synflood/all` | List SYN flood configurations | Yes |

```bash
# Source: api/swagger.yml — POST /config/synflood
curl -X POST http://localhost:11111/netlox/v1/config/synflood \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "interface": "eth0",
    "rate": 1000,
    "burst": 2000
  }'

# Response (200): {"result": "Success"}
```

### Security Rate Limiter

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/securityrate` | Create security rate limiter | Yes |
| DELETE | `/config/securityrate` | Delete security rate limiter | Yes |
| GET | `/config/securityrate/all` | List rate limiters | Yes |
| PUT | `/config/securityrate/reset` | Reset rate limiter statistics | Yes |

```bash
# Source: api/swagger.yml — POST /config/securityrate
curl -X POST http://localhost:11111/netlox/v1/config/securityrate \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "api-rate-limit",
    "rate": 500,
    "burst": 1000,
    "target": "10.0.0.0/24"
  }'

# Response (200): {"result": "Success"}
```

### IP Filter

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/ipfilter` | Create IP filter rule | Yes |
| DELETE | `/config/ipfilter` | Delete IP filter rule | Yes |
| GET | `/config/ipfilter/all` | List IP filters | Yes |

```bash
# Source: api/swagger.yml — POST /config/ipfilter
curl -X POST http://localhost:11111/netlox/v1/config/ipfilter \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "source": "192.168.1.0/24",
    "action": "allow"
  }'

# Response (200): {"result": "Success"}
```

## SNI Certificates

!!! enterprise "Enterprise Feature"
    SNI certificate management for HTTPS and mTLS termination is enterprise-only.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/sni/certificates` | Upload SNI certificate bundle | Yes |
| DELETE | `/sni/certificates` | Remove certificate | Yes |
| GET | `/sni/certificates` | List certificates | Yes |

### Upload SNI Certificate

```bash
# Source: api/swagger.yml — POST /sni/certificates
curl -X POST http://localhost:11111/netlox/v1/sni/certificates \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "domain": "api.example.com",
    "certificate": "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----"
  }'

# Response (201): Certificate uploaded
```

### List Certificates

```bash
# Source: api/swagger.yml — GET /sni/certificates
curl http://localhost:11111/netlox/v1/sni/certificates \
  -H "Authorization: Bearer eyJhbG..."

# Response (200):
# [
#   {
#     "domain": "api.example.com",
#     "issuer": "Let's Encrypt",
#     "not_after": "2025-06-15T00:00:00Z"
#   }
# ]
```

## Observability

!!! enterprise "Enterprise Feature"
    Enterprise observability endpoints provide log management, node graph topology, worker metrics, and Prometheus metrics.

### Logs

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| GET | `/logs` | Retrieve log entries | Yes |
| GET | `/log-archives` | List log archive files | Yes |
| GET | `/log-archives/{filename}` | Download specific log archive | Yes |

```bash
# Source: api/swagger.yml — GET /logs
curl http://localhost:11111/netlox/v1/logs \
  -H "Authorization: Bearer eyJhbG..."

# Response (200): Log entries (JSON array)
```

### Node Graph

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| GET | `/nodegraph/all` | Get full node graph topology | Yes |
| GET | `/nodegraph/{service}` | Get node graph for specific service | Yes |

```bash
# Source: api/swagger.yml — GET /nodegraph/all
curl http://localhost:11111/netlox/v1/nodegraph/all \
  -H "Authorization: Bearer eyJhbG..."

# Response (200): Node graph topology data (JSON)
```

### Worker Metrics

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| GET | `/config/worker/metrics` | Get worker metrics configuration | Yes |
| POST | `/config/worker/metrics` | Update worker metrics settings | Yes |

```bash
# Source: api/swagger.yml — POST /config/worker/metrics
curl -X POST http://localhost:11111/netlox/v1/config/worker/metrics \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{"enabled": true, "interval_sec": 10}'

# Response (200): {"result": "Success"}
```

### Prometheus Metrics

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| GET | `/metrics` | All Prometheus metrics | Yes |
| GET | `/metrics/{type}` | Specific metric series | Yes |

Available metric types: `flowcount`, `hostcount`, `lbrulecount`, `newflowcount`, `requestcount`, `errorcount`, `processedtraffic`, `lbprocessedtraffic`, `epdisttraffic`, `servicedisttraffic`, `fwdrops`, `reqcountperclient`

```bash
# Source: api/swagger.yml — GET /metrics/requestcount
curl http://localhost:11111/netlox/v1/metrics/requestcount \
  -H "Authorization: Bearer eyJhbG..."

# Response (200): Prometheus-formatted metric data
```

For Prometheus scrape configuration and Grafana dashboard setup, see [Monitoring Setup](../operations/monitoring.md).

## CORS Configuration

!!! enterprise "Enterprise Feature"
    CORS configuration for the loxilb API is enterprise-only.

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| POST | `/config/cors` | Create CORS rule | Yes |
| DELETE | `/config/cors/{cors_url}` | Delete CORS rule | Yes |
| GET | `/config/cors/all` | List CORS rules | Yes |

```bash
# Source: api/swagger.yml — POST /config/cors
curl -X POST http://localhost:11111/netlox/v1/config/cors \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "cors_url": "https://dashboard.example.com"
  }'

# Response (200): {"result": "Success"}
```

## Metadata

| Method | Path | Description | Auth Required |
|--------|------|-------------|:---:|
| GET | `/meta` | API metadata and required fields | No |

```bash
# Source: api/swagger.yml — GET /meta
curl http://localhost:11111/netlox/v1/meta

# Response (200): API metadata including POST required fields
```

## Community API Baseline

The enterprise binary includes the full community API surface. These endpoints behave identically in the enterprise binary. Enterprise additions are documented in the sections above.

| Endpoint Group | Description |
|----------------|-------------|
| `/config/loadbalancer` | Load balancer rules (CRUD) |
| `/config/route` | Static routes |
| `/config/vlan` | VLAN bridge configuration |
| `/config/vxlan` | VxLAN tunnel configuration |
| `/config/fdb` | FDB entry management |
| `/config/neighbor` | ARP neighbor entries |
| `/config/port` | Network port configuration |
| `/config/conntrack` | Connection tracking entries |
| `/config/firewall` | Firewall rules |
| `/config/policy` | QoS policies |
| `/config/mirror` | Traffic mirroring |
| `/config/session` | GTP session management |
| `/config/sessionulcl` | Session UlCl rules |
| `/config/cistate` | Cluster instance state |
| `/config/bfd` | BFD session management |
| `/config/bgp` | BGP neighbor and policy configuration |
| `/config/endpoint` | Health probe endpoints |
| `/config/ipv4address` | IPv4 address management |
| `/config/params` | System parameters |
| `/status` | Process status |
| `/version` | Version information |

For complete documentation of community endpoints, see the [Community API Reference (SwaggerHub)](https://app.swaggerhub.com/apis-docs/ADMIN_111/loxilb/1.0.0).

!!! note "Community Compatibility"
    These endpoints behave identically in the enterprise binary. Enterprise additions are documented in the sections above.
