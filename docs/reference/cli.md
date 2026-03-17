# Enterprise CLI Reference

!!! enterprise "Enterprise Feature"
    This reference covers the enterprise `loxicmd` binary. Enterprise-only subcommands are marked with :material-star:{ .enterprise } badges.
    For community CLI documentation, see the [Community CLI Reference](../cmd.md).

## Overview

The enterprise `loxicmd` binary is the command-line interface for managing loxilb-enterprise. It uses the same binary name as the community edition — the enterprise build adds additional subcommands for AI gateway, OPA policy, L4 tracing, authentication, and other enterprise features.

- **Version:** 0.9.8.3-beta
- **Source:** `cmd/loxicmd-enterprise/cmd/root.go`
- **API communication:** All commands interact with the loxilb REST API at `http(s)://<apiserver>:<port>/netlox/v1`

## Global Flags

All subcommands inherit these persistent flags from the root command:

| Flag | Short | Default | Description |
|------|:---:|---------|-------------|
| `--timeout` | `-t` | `10` | API call timeout in seconds |
| `--protocol` | | `http` | API server protocol (`http` or `https`) |
| `--output` | `-o` | | Output format: `wide` or `json` |
| `--apiserver` | `-s` | `127.0.0.1` | API server IP address |
| `--port` | `-p` | `11111` | API server port number |
| `--token` | | | JWT token for authentication (overrides stored token) |

!!! note "Token Resolution"
    When `--token` is not provided, `loxicmd` reads the stored token from `/tmp/loxilbtoken` (created by `loxicmd set login`). You can override this for one-off commands by passing `--token` directly.

## Authentication Workflow

Authentication is the entry point for all enterprise CLI operations. The workflow stores a JWT token locally for subsequent commands.

```bash
# Step 1: Login (stores token to /tmp/loxilbtoken)
loxicmd set login
# Enter username: admin
# Enter password: ****
# Token stored to /tmp/loxilbtoken

# Step 2: Use any command (token is read automatically)
loxicmd get lb
loxicmd get ai-apikeys

# Step 3: Logout (removes stored token)
loxicmd set logout
```

**Alternative authentication methods:**

```bash
# Google OAuth2
loxicmd set login --provider google
# Enter access token: ...
# Enter refresh token: ...

# Manual token (for license upgrades or CI/CD)
loxicmd set login --provider manual
# Enter token: ...
```

**Token storage locations:**

| File | Purpose |
|------|---------|
| `/tmp/loxilbtoken` | JWT access token (all auth modes) |
| `/tmp/loxilbrefreshtoken` | Google OAuth2 refresh token |

For detailed authentication configuration on the server side, see [User Management](../operations/user-management.md).

## `loxicmd create`

Create new resources. Enterprise-only subcommands are marked with :material-star:{ .enterprise }.

### Enterprise Subcommands

| Subcommand | Description | Key Flags |
|------------|-------------|-----------|
| :material-star: `l4trace` | Enable L4 connection tracing | `--sampling` (0–100, default: 100) |
| :material-star: `ai-apikey` | Create AI Gateway API key | `--tenant-id` (required), `--name`, `--allowed-models`, `--rate-limit-rps`, `--burst-size`, `--tokens-per-min`, `--expires-at` |
| :material-star: `ai-tenant-ratelimit` | Set tenant rate limit | `--tenant-id` (required), `--rps`, `--tokens-per-min` |
| :material-star: `opa-watcher` | Configure OPA L4 policy watcher | `--opa-url` (required), `--policy-path`, `--poll-interval-sec`, `--fail-open` |

#### Create AI API Key

```bash
# Source: cmd/loxicmd-enterprise/cmd/create/create_aigateway.go
loxicmd create ai-apikey \
  --tenant-id "acme-corp" \
  --name "production-key" \
  --allowed-models "gpt-4,claude-3" \
  --rate-limit-rps 100 \
  --burst-size 200 \
  --tokens-per-min 50000 \
  --expires-at "2025-12-31T23:59:59Z"
```

**Flags:**

| Flag | Type | Required | Default | Description |
|------|------|:---:|---------|-------------|
| `--tenant-id` | string | Yes | | Tenant identifier |
| `--name` | string | No | | Human-readable key name |
| `--allowed-models` | strings | No | | Comma-separated allowed model names |
| `--rate-limit-rps` | int64 | No | 0 | Rate limit in requests/second |
| `--burst-size` | int64 | No | 0 | Burst size for rate limiting |
| `--tokens-per-min` | int64 | No | 0 | Token quota per minute |
| `--expires-at` | string | No | | Expiration time (RFC 3339 format) |

#### Enable L4 Connection Tracing

```bash
# Source: cmd/loxicmd-enterprise/cmd/create/create_l4trace.go
# Enable L4 tracing at 50% sampling
loxicmd create l4trace --sampling 50

# Enable L4 tracing at full sampling (default)
loxicmd create l4trace
```

**Flags:**

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--sampling` | int | 100 | Sampling rate 0–100% |

#### Set Tenant Rate Limit

```bash
loxicmd create ai-tenant-ratelimit \
  --tenant-id "acme-corp" \
  --rps 200 \
  --tokens-per-min 100000
```

**Flags:**

| Flag | Type | Required | Default | Description |
|------|------|:---:|---------|-------------|
| `--tenant-id` | string | Yes | | Tenant identifier |
| `--rps` | int64 | No | 0 | Rate limit in requests/second |
| `--tokens-per-min` | int64 | No | 0 | Token quota per minute |

#### Configure OPA Policy Watcher

```bash
# Source: cmd/loxicmd-enterprise/cmd/create/create_opa_watcher.go
loxicmd create opa-watcher \
  --opa-url "http://opa-server:8181" \
  --policy-path "loxilb/l4" \
  --poll-interval-sec 30 \
  --fail-open
```

**Flags:**

| Flag | Type | Required | Default | Description |
|------|------|:---:|---------|-------------|
| `--opa-url` | string | Yes | | OPA server URL |
| `--policy-path` | string | No | `loxilb/l4` | OPA policy path |
| `--poll-interval-sec` | int | No | 30 | Poll interval in seconds |
| `--fail-open` | bool | No | false | Allow traffic when OPA is unreachable |

### Community Subcommands

These subcommands are inherited from the community `loxicmd`. See [Community CLI Reference](../cmd.md) for full documentation.

| Subcommand | Description |
|------------|-------------|
| `lb` | Load balancer rule |
| `session` | GTP session |
| `sessionulcl` | Session UlCl |
| `policy` | QoS policy |
| `route` | Static route |
| `ipaddress` | IPv4 address |
| `neighbor` | ARP neighbor |
| `fdb` | FDB entry |
| `vlan` | VLAN bridge |
| `vlan-member` | VLAN member port |
| `vxlan` | VxLAN bridge |
| `vxlan-peer` | VxLAN peer |
| `mirror` | Traffic mirror |
| `firewall` | Firewall rule |
| `ipfilter` | IP filter rule |
| `synflood` | SYN flood protection |
| `securityrate` | Security rate limiter |
| `endpoint` | Health probe endpoint |
| `bgpneighbor` | BGP neighbor |
| `bfd` | BFD session |
| `sni` | SNI certificate |

## `loxicmd get`

Retrieve resource information. Enterprise-only subcommands are marked with :material-star:{ .enterprise }.

### Enterprise Subcommands

| Subcommand | Description | Arguments |
|------------|-------------|-----------|
| :material-star: `l4trace` | L4 tracing status and statistics | None |
| :material-star: `ai-apikeys` | List all AI API keys | `--tenant-id` (optional filter) |
| :material-star: `ai-apikey KEY_ID` | Get specific AI API key | Positional: KEY_ID |
| :material-star: `ai-tenant-ratelimit TENANT_ID` | Get tenant rate limit | Positional: TENANT_ID |
| :material-star: `llm-catalogs` | List LLM catalog profiles | None |
| :material-star: `llm-catalog NAME` | Get specific LLM catalog | Positional: NAME |
| :material-star: `trace` | OTLP tracing status | None |
| :material-star: `opa-watcher` | OPA watcher status | None |

```bash
# List AI API keys filtered by tenant
loxicmd get ai-apikeys --tenant-id "acme-corp"

# Get L4 tracing status and statistics
loxicmd get l4trace

# List LLM catalog profiles
loxicmd get llm-catalogs

# Get specific LLM catalog
loxicmd get llm-catalog gpt-4-turbo

# Get OTLP tracing status
loxicmd get trace

# Get OPA watcher status
loxicmd get opa-watcher

# Get specific AI API key
loxicmd get ai-apikey ak_abc123def456

# Get tenant rate limit
loxicmd get ai-tenant-ratelimit acme-corp
```

### Community Subcommands

See [Community CLI Reference](../cmd.md) for full documentation.

| Subcommand | Description |
|------------|-------------|
| `lb` | Load balancer rules |
| `conntrack` | Connection tracking |
| `port` | Network ports |
| `session` | GTP sessions |
| `sessionulcl` | Session UlCl |
| `policy` | QoS policies |
| `route` | Routes |
| `ipaddress` | IP addresses |
| `neighbor` | ARP neighbors |
| `status` | Process status |
| `vlan` | VLANs |
| `mirror` | Traffic mirrors |
| `firewall` | Firewall rules |
| `ipfilter` | IP filters |
| `synflood` | SYN flood configurations |
| `securityrate` | Security rate limiters |
| `vxlan` | VxLAN configurations |
| `endpoint` | Health endpoints |
| `hastate` | HA state |
| `bgpneighbor` | BGP neighbors |
| `bfd` | BFD sessions |
| `version` | loxilb version |
| `sni` | SNI certificates |

## `loxicmd delete`

Delete resources. Enterprise-only subcommands are marked with :material-star:{ .enterprise }.

### Enterprise Subcommands

| Subcommand | Description | Arguments |
|------------|-------------|-----------|
| :material-star: `l4trace` | Disable L4 tracing | None |
| :material-star: `ai-apikey KEY_ID` | Delete AI API key | Positional: KEY_ID |
| :material-star: `opa-watcher` | Stop OPA watcher | None |
| :material-star: `trace` | Disable OTLP tracing | None |

```bash
# Delete an AI API key
loxicmd delete ai-apikey abc123

# Disable L4 tracing
loxicmd delete l4trace

# Stop OPA watcher
loxicmd delete opa-watcher

# Disable OTLP tracing
loxicmd delete trace
```

!!! tip "File-Based Deletion"
    `loxicmd delete` also supports `-f/--file <config.yaml>` for declarative deletion from YAML configuration files.

### Community Subcommands

See [Community CLI Reference](../cmd.md) for full documentation.

| Subcommand | Description |
|------------|-------------|
| `lb` | Load balancer rule |
| `session` | GTP session |
| `sessionulcl` | Session UlCl |
| `policy` | QoS policy |
| `route` | Static route |
| `ipaddress` | IPv4 address |
| `neighbor` | ARP neighbor |
| `fdb` | FDB entry |
| `vlan` | VLAN bridge |
| `vlan-member` | VLAN member port |
| `vxlan` | VxLAN bridge |
| `vxlan-peer` | VxLAN peer |
| `mirror` | Traffic mirror |
| `firewall` | Firewall rule |
| `ipfilter` | IP filter rule |
| `synflood` | SYN flood protection |
| `securityrate` | Security rate limiter |
| `endpoint` | Health probe endpoint |
| `bgpneighbor` | BGP neighbor |
| `bfd` | BFD session |
| `sni` | SNI certificate |

## `loxicmd set`

Configure settings. Enterprise-only subcommands are marked with :material-star:{ .enterprise }.

### Enterprise Subcommands

| Subcommand | Description | Key Flags |
|------------|-------------|-----------|
| :material-star: `login` | Authenticate and store JWT | `--provider` (empty=local, `google`, `manual`) |
| :material-star: `logout` | Invalidate and remove token | `--provider` |
| :material-star: `refresh` | Refresh OAuth2 token | `--provider` (only `google`) |
| :material-star: `trace` | Configure OTLP tracing | (tracing parameters) |
| :material-star: `l4trace-sampling` | Update L4 sampling rate | (sampling rate 0–100) |

#### Login Workflow

```bash
# Local authentication (interactive — prompts for username and password)
loxicmd set login
# Enter username: admin
# Enter password: ****
# Token stored to /tmp/loxilbtoken

# Google OAuth2 (prompts for access token and refresh token)
loxicmd set login --provider google
# Enter access token: ...
# Enter refresh token: ...
# Tokens stored to /tmp/loxilbtoken and /tmp/loxilbrefreshtoken

# Manual token (for license upgrades or CI/CD pipelines)
loxicmd set login --provider manual
# Enter token: ...
# Token stored to /tmp/loxilbtoken
```

**`set login` Flags:**

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--provider` | string | (empty = local) | Auth provider: empty (local), `google`, `manual` |

#### Refresh OAuth2 Token

```bash
# Refresh Google OAuth2 token (reads existing tokens from /tmp/)
loxicmd set refresh --provider google
```

#### Logout

```bash
# Local logout (calls POST /auth/logout and removes /tmp/loxilbtoken)
loxicmd set logout

# Google OAuth2 logout (removes both token files)
loxicmd set logout --provider google
```

#### Configure OTLP Tracing

```bash
loxicmd set trace --endpoint http://jaeger:4318 --service-name loxilb-gateway
```

#### Update L4 Sampling Rate

```bash
# Set L4 tracing sampling rate to 25%
loxicmd set l4trace-sampling 25
```

### Community Subcommands

| Subcommand | Description |
|------------|-------------|
| `bfd` | BFD session parameters |
| (log-level) | Set log level |

See [Community CLI Reference](../cmd.md) for full documentation.

## `loxicmd reset`

Reset statistics and counters. All `reset` subcommands are enterprise-only.

| Subcommand | Description |
|------------|-------------|
| :material-star: `securityrate-stats` | Reset security rate limiter statistics |
| :material-star: `l4trace-stats` | Reset L4 connection tracing statistics |

```bash
# Reset security rate limiter statistics
loxicmd reset securityrate-stats

# Reset L4 connection tracing statistics
loxicmd reset l4trace-stats
```

## `loxicmd save`

Save current loxilb configuration to files. This command is inherited from the community edition with no enterprise additions.

```bash
# Save all configuration
loxicmd save --all

# Save specific configuration subset
loxicmd save --lb          # Load balancer rules only
loxicmd save --ip          # IP configuration only
loxicmd save --session     # Session configuration only
loxicmd save --firewall    # Firewall rules only
loxicmd save --endpoint    # Endpoint configuration only
loxicmd save --bfd         # BFD configuration only

# Custom config file location
loxicmd save --all --config-path /etc/loxilb/backup/
```

See [Community CLI Reference](../cmd.md) for full documentation.

## `loxicmd apply`

Apply configuration from files. This command is inherited from the community edition with no enterprise additions.

```bash
# Apply load balancer configuration from file
loxicmd apply --lb lb-config.yaml

# Apply from generic K8s-style config file
loxicmd apply --file config.yaml

# Apply only for specific interface
loxicmd apply --lb lb-config.yaml --per-intf eth0

# Custom config path
loxicmd apply --lb --config-path /etc/loxilb/configs/
```

See [Community CLI Reference](../cmd.md) for full documentation.

## `loxicmd completion`

Generate shell completion scripts for tab completion.

```bash
# Bash
loxicmd completion bash > /etc/bash_completion.d/loxicmd

# Zsh
loxicmd completion zsh > "${fpath[1]}/_loxicmd"

# Fish
loxicmd completion fish > ~/.config/fish/completions/loxicmd.fish

# PowerShell
loxicmd completion powershell > loxicmd.ps1
```

## `loxicmd version`

Print version and build information.

```bash
loxicmd version
# loxicmd version 0.9.8.3-beta
```

## Enterprise Command Quick Reference

All enterprise-only commands in one table for quick lookup:

| Command | Description |
|---------|-------------|
| `create ai-apikey` | Create AI Gateway API key |
| `create ai-tenant-ratelimit` | Set tenant rate limit |
| `create l4trace` | Enable L4 connection tracing |
| `create opa-watcher` | Configure OPA policy watcher |
| `get ai-apikeys` | List AI API keys |
| `get ai-apikey KEY_ID` | Get specific API key |
| `get ai-tenant-ratelimit TENANT_ID` | Get tenant rate limit |
| `get l4trace` | L4 tracing status and statistics |
| `get llm-catalogs` | List LLM catalog profiles |
| `get llm-catalog NAME` | Get specific catalog |
| `get trace` | OTLP tracing status |
| `get opa-watcher` | OPA watcher status |
| `delete ai-apikey KEY_ID` | Delete API key |
| `delete l4trace` | Disable L4 tracing |
| `delete opa-watcher` | Stop OPA watcher |
| `delete trace` | Disable OTLP tracing |
| `set login` | Authenticate and store JWT |
| `set logout` | Invalidate token |
| `set refresh` | Refresh OAuth2 token |
| `set trace` | Configure OTLP tracing |
| `set l4trace-sampling` | Update sampling rate |
| `reset securityrate-stats` | Reset rate limiter statistics |
| `reset l4trace-stats` | Reset L4 trace statistics |

## See Also

- [API Reference](api.md) — corresponding REST endpoints for each CLI command
- [Community CLI Reference](../cmd.md) — full documentation for community subcommands
- [User Management](../operations/user-management.md) — authentication setup and configuration
