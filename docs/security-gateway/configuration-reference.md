# Security Gateway Configuration Reference

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

This page provides a consolidated reference for **all** Security Gateway configuration fields, verified against `swagger.yml`. For detailed explanations and examples, see the linked feature pages. For the full REST API documentation, see the [API Reference](../reference/api.md).

## Quick Reference

**Most commonly configured fields:**

- **OPA:** `opa_url`, `policy_path`, `fail_open` — [OPA Policy Enforcement](opa-policy-enforcement.md)
- **Rate Limiting:** `rate_limit_rps`, `daily_token_quota` — [Rate Limiting](rate-limiting.md)
- **SYN Flood:** `synEnabled`, `synThreshold`, `whitelistIps` — [SYN Flood Protection](syn-flood.md)
- **IP Filtering:** `filterType`, `cidr`, `action` — [IP Filtering](ip-filtering.md)
- **mTLS:** `client_cert_mode`, `client_ca_path`, `verify_server_cert` — [mTLS Configuration](mtls.md)
- **IPsec:** `encryption`, `integrity`, `local_ip`, `remote_ip` — [IPsec Configuration](ipsec.md)

---

## OPA Watcher Configuration

**Endpoint:** `POST /config/opa/watcher`
**Detail page:** [OPA Policy Enforcement](opa-policy-enforcement.md)

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `opa_url` | string | Any HTTP/HTTPS URL | (required) | OPA server URL |
| `policy_path` | string | OPA policy path | `"loxilb/l4"` | Rego package path to query |
| `poll_interval_sec` | int | `> 0` | `30` | Seconds between policy fetches |
| `fail_open` | bool | `true`, `false` | `false` | Allow traffic when OPA unreachable |
| `initial_delay_sec` | int | `>= 0` | `10` | Seconds before first poll |
| `loxilb_url` | string | Any HTTP/HTTPS URL | `"http://localhost:11111"` | loxilb REST API base URL |
| `state_path` | string | File system path | `""` | File path for watcher state persistence |

## LlamaFirewall Configuration

**Endpoint:** `POST /config/llamafirewall/enable`, `POST /config/llamafirewall/scanners`
**Detail page:** [LlamaFirewall](llamafirewall.md)

### Enable/Disable

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `server_url` | string | `host:port` | `"localhost:50052"` | LlamaFirewall gRPC endpoint |
| `timeout_sec` | int | `> 0` | `15` | gRPC call timeout in seconds |
| `fail_closed` | int | `0`, `1` | `0` | 0=fail-open (allow on error), 1=fail-closed (block on error) |
| `block_threshold` | float | `0.0`–`1.0` | `0.9` | Score threshold for blocking requests |
| `cache_ttl` | int | `> 0` | `300` | Cache TTL in seconds for scan results |
| `connection_pool_size` | int | `> 0` | `10` | gRPC connection pool size |

### Scanner Configuration

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `prompt_guard` | bool | `true`, `false` | `true` | Enable prompt injection scanner |
| `code_shield` | bool | `true`, `false` | `true` | Enable code vulnerability scanner |
| `regex` | bool | `true`, `false` | `true` | Enable regex credential scanner |
| `hidden_ascii` | bool | `true`, `false` | `true` | Enable hidden character scanner |
| `agent_alignment` | bool | `true`, `false` | `false` | Enable agent misalignment scanner |
| `pii_detection` | bool | `true`, `false` | `false` | Enable PII detection scanner |

## Presidio Configuration

**Endpoint:** `POST /config/pii/enable`, `POST /config/pii/configure`
**Detail page:** [Presidio PII Detection](presidio-pii-detection.md)

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `presidio_url` | string | Any HTTP/HTTPS URL | (required) | Presidio Analyzer endpoint |
| `score_threshold` | float | `0.0`–`1.0` | `0.7` | Minimum confidence for PII detection |
| `entities` | string[] | PII entity type names | All entities | PII entity types to detect |
| `action` | string | `"redact"`, `"mask"`, `"log"` | `"redact"` | Action when PII detected |
| `direction` | string | `"request"`, `"response"`, `"both"` | `"request"` | Scan direction |
| `fail_mode` | string | `"open"`, `"closed"` | (configurable) | Behavior when Presidio unreachable |

## Rate Limiting Configuration (API Key)

**Endpoint:** `POST /config/ai/apikey`
**Detail page:** [Rate Limiting](rate-limiting.md)

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `key_name` | string | Any unique string | (required) | API key identifier |
| `rate_limit_rps` | int | `> 0` (requests/sec) | — | Sustained requests per second per key |
| `burst_size` | int | `> 0` (requests) | — | Maximum burst capacity (token bucket size) |
| `daily_token_quota` | int | `> 0` (tokens) | — | LLM token quota per day per key |
| `concurrent_limit` | int | `> 0` (connections) | — | Maximum concurrent requests per key |

## SecurityRateConfig (SYN Flood + Connection Rate + UDP Flood)

**Endpoint:** `POST /config/securityrate`
**Detail page:** [SYN Flood Protection](syn-flood.md)

!!! info "All fields required"
    The unified SecurityRateConfig endpoint requires all fields in the POST body. Set unused protections to `false` / `0`.

### SYN Flood Protection (P0-5)

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `synEnabled` | bool | `true`, `false` | `false` | Enable SYN flood protection |
| `synThreshold` | integer (int64) | `> 0` (packets/sec) | `100` | Max SYNs per second per IP (hard drop threshold) |
| `cookieThreshold` | integer (int64) | `> 0` (cookies/sec) | `50` | SYN cookie activation threshold (must be < synThreshold) |

### Connection Rate Limiting (P0-6)

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `connRateEnabled` | bool | `true`, `false` | `false` | Enable connection rate limiting |
| `ratePerSec` | integer (int64) | `> 0` (connections/sec) | `50` | Max new connections per second per IP |
| `concurrentLimit` | integer (int64) | `> 0` (connections) | `200` | Max concurrent connections per IP |

### UDP Flood Protection (P0-7)

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `udpEnabled` | bool | `true`, `false` | `false` | Enable UDP flood protection |
| `udpPktThreshold` | integer (int64) | `> 0` (packets/sec) | `1000` | Max UDP packets per second per IP |
| `udpBandwidthMB` | integer (int64) | `> 0` (MB/s) | `100` | Max UDP bandwidth in MB/sec per IP |

### Shared

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `whitelistIps` | string[] | Array of CIDR strings | `[]` | CIDRs exempt from all rate controls |

### Read-Only Statistics (GET /config/securityrate/all)

| Field | Type | Description |
|-------|------|-------------|
| `activeSynCookies` | integer | Active SYN cookie challenges in progress |
| `totalDropped` | integer | Total packets dropped by all rate controls |
| `trackedIps` | integer | Number of unique source IPs being tracked |

## Legacy SYN Flood Configuration

**Endpoint:** `POST /config/synflood`
**Detail page:** [SYN Flood Protection](syn-flood.md)

!!! note "Use SecurityRateConfig for new deployments"
    The legacy `/config/synflood` endpoint is maintained for backward compatibility. New deployments should use the unified `/config/securityrate` endpoint above.

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `enabled` | bool | `true`, `false` | (required) | Enable/disable SYN flood protection |
| `synThreshold` | integer (int64) | `> 0` (packets/sec) | `100` | Max SYNs per second per IP |
| `cookieThreshold` | integer (int64) | `> 0` (cookies/sec) | `50` | SYN cookie activation threshold |
| `whitelistIps` | string[] | Array of CIDR strings | `[]` | CIDRs exempt from SYN rate controls |

## IP Filter Configuration

**Endpoint:** `POST /config/ipfilter`, `DELETE /config/ipfilter`, `GET /config/ipfilter/all`
**Detail page:** [IP Filtering](ip-filtering.md)

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `filterType` | string | `"whitelist"`, `"blacklist"` | (required) | Filter list type |
| `cidr` | string | CIDR notation (e.g., `"192.168.1.0/24"`) | (required) | IP range to filter |
| `zone` | integer (int64) | `0` to N | `0` | Security zone (0 = all zones) |
| `priority` | integer (int64) | `> 0` (higher = more important) | `100` | Rule priority within same zone |
| `action` | string | `"allow"`, `"drop"` | (required) | Action when rule matches |
| `packets` | integer (int64) | — | `0` | Packet counter (read-only) |
| `bytes` | integer (int64) | — | `0` | Byte counter (read-only) |

## IPsec Global Configuration

**Endpoint:** `POST /config/ipsec`
**Detail page:** [IPsec Configuration](ipsec.md)

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `fast_path_enabled` | bool | `true`, `false` | `true` | Enable eBPF fast path for IPsec |
| `hw_offload_enabled` | bool | `true`, `false` | `false` | QAT/DPAA2 crypto hardware offload |
| `anti_replay_enabled` | bool | `true`, `false` | `true` | IPsec anti-replay protection |
| `sa_lifetime_warn_seconds` | int | `> 0` (seconds) | `300` | SA expiry warning threshold |
| `mtu` | int | `> 0` (bytes) | `1400` | IPsec tunnel MTU |

## IPsec Tunnel Configuration

**Endpoint:** `POST /config/ipsec/tunnels`, `DELETE /config/ipsec/tunnels`, `GET /config/ipsec/tunnels/all`
**Detail page:** [IPsec Configuration](ipsec.md)

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `name` | string | Any unique string | (required) | Unique tunnel identifier |
| `local_ip` | string | IPv4 address | (required) | Local endpoint IP |
| `remote_ip` | string | IPv4 address | (required) | Remote endpoint IP |
| `auth_method` | string | `"psk"`, `"cert"` | (required) | Authentication method |
| `ike_version` | int | `1`, `2` | `2` | IKE protocol version |
| `encryption` | string | `"aes128"`, `"aes256"`, `"3des"` | `"aes256"` | IKE encryption algorithm |
| `integrity` | string | `"sha256"`, `"sha384"`, `"sha512"` | `"sha256"` | IKE integrity algorithm |
| `dh_group` | string | `"modp1024"`, `"modp2048"`, `"modp4096"` | `"modp2048"` | IKE DH group |
| `esp_encryption` | string | `"aes128"`, `"aes256"`, `"3des"` | `"aes256"` | ESP encryption algorithm |
| `esp_integrity` | string | `"sha256"`, `"sha384"`, `"sha512"` | `"sha256"` | ESP integrity algorithm |
| `tunnel_mode` | string | `"tunnel"`, `"transport"` | `"tunnel"` | IPsec mode |
| `auto` | string | `"start"`, `"add"`, `"route"` | `"start"` | Auto-initiation mode |
| `local_subnet` | string | CIDR notation | (required) | Local subnet for tunnel |
| `remote_subnet` | string | CIDR notation | (required) | Remote subnet for tunnel |

## mTLS Frontend Configuration

**Config mechanism:** Part of load balancer rule (`mtls_frontend` field in PUT `/config/loadbalancer/{name}`)
**Detail page:** [mTLS Configuration](mtls.md)

!!! info "Requires FullProxy mode"
    mTLS fields are only valid with `security=1` (HTTPS) or `security=2` (E2E HTTPS) and `mode=4` (FullProxy).

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `client_cert_mode` | string | `"disabled"`, `"optional"`, `"required"` | `"disabled"` | Client certificate requirement level |
| `client_ca_path` | string | File system path | — | Path to CA bundle for validating client certs (PEM) |
| `client_ca_cert_data` | string | Base64-encoded PEM | — | Inline CA certificate (for Kubernetes secrets) |
| `require_client_cn` | bool | `true`, `false` | `false` | Enforce CN pattern matching |
| `client_cn_pattern` | string | Glob pattern | — | Pattern for allowed CNs (fnmatch syntax: `*`, `?`) |

## mTLS Backend Configuration

**Config mechanism:** Part of load balancer rule (`mtls_backend` field in PUT `/config/loadbalancer/{name}`)
**Detail page:** [mTLS Configuration](mtls.md)

!!! info "Requires E2E HTTPS"
    Backend mTLS requires `security=2` (E2E HTTPS) and `mode=4` (FullProxy).

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `verify_server_cert` | bool | `true`, `false` | `false` | Validate backend server cert (`SSL_VERIFY_PEER`) |
| `backend_ca_path` | string | File system path | — | CA bundle for verifying backend certs. Empty = system CA store. |
| `client_cert_path` | string | File system path | — | loxilb's client certificate for backend auth |
| `client_key_path` | string | File system path | — | Private key for backend client certificate |
| `client_cert_data` | string | Base64-encoded PEM | — | Inline client certificate |
| `client_key_data` | string | Base64-encoded PEM | — | Inline client key |

## Port Allocation Summary

| Service | Default Port | Protocol | Notes |
|---------|:----:|----------|-------|
| loxilb API | 11111 | HTTP | Main management API |
| OPA Server | 8181 | HTTP | Policy evaluation |
| Presidio Analyzer | 50051 | gRPC | PII entity recognition |
| LlamaFirewall | 50052 | gRPC | AI safety scanning |

!!! warning "Port conflict prevention"
    Presidio (50051) and LlamaFirewall (50052) must use different ports. Verify assignments when deploying both services on the same host.

## REST API Endpoints Summary

### Security Policy

| Endpoint | Method | Feature |
|----------|--------|---------|
| `/config/opa/watcher` | POST / GET / DELETE | OPA watcher management |
| `/config/pii/enable` | POST | Enable Presidio PII detection |
| `/config/pii/configure` | POST | Configure PII detection parameters |
| `/config/pii/status` | GET | PII detection status and health |
| `/config/llamafirewall/enable` | POST | Enable LlamaFirewall |
| `/config/llamafirewall/scanners` | POST | Configure scanner modules |
| `/config/llamafirewall/status` | GET | LlamaFirewall status and health |

### Rate Limiting and DDoS

| Endpoint | Method | Feature |
|----------|--------|---------|
| `/config/ai/apikey` | POST / GET / DELETE | API key with rate limits |
| `/config/securityrate` | POST | Unified SYN flood + connection rate + UDP flood |
| `/config/securityrate/all` | GET | Current config + statistics |
| `/config/securityrate/reset` | PUT | Reset rate statistics counters |
| `/config/synflood` | POST | Legacy SYN flood (use securityrate instead) |
| `/config/ipfilter` | POST / DELETE | IP filter rule management |
| `/config/ipfilter/all` | GET | List all rules with hit counters |

### Transport Security

| Endpoint | Method | Feature |
|----------|--------|---------|
| `/config/ipsec` | POST | IPsec global configuration |
| `/config/ipsec/tunnels` | POST / DELETE | IPsec tunnel management |
| `/config/ipsec/tunnels/all` | GET | List all tunnels with status |
| `/config/ipsec/certificates` | POST / DELETE | IPsec certificate management |
| `/config/loadbalancer/{name}` | PUT | Load balancer rule (contains mTLS fields) |

## Configuration Verification Checklist

After deploying any Security Gateway scenario, verify the configuration is correct:

```bash
# Verify all active security components
curl http://loxilb:11111/netlox/v1/config/opa/watcher -H "Authorization: Bearer <token>"
curl http://loxilb:11111/netlox/v1/config/llamafirewall/status -H "Authorization: Bearer <token>"
curl http://loxilb:11111/netlox/v1/config/pii/status -H "Authorization: Bearer <token>"
curl http://loxilb:11111/netlox/v1/config/securityrate/all -H "Authorization: Bearer <token>"
curl http://loxilb:11111/netlox/v1/config/ipfilter/all -H "Authorization: Bearer <token>"
curl http://loxilb:11111/netlox/v1/config/ipsec/tunnels/all -H "Authorization: Bearer <token>"
```

Each response should show the expected configuration values. For load balancer rules with mTLS, check the `mtls_frontend` and `mtls_backend` fields in the rule response.

## See Also

- [Full API Reference](../reference/api.md) — Complete REST API documentation with all endpoints
- [Security Gateway Overview](overview.md) — Architecture diagram, fail-mode table
- [Deployment Scenarios](deployment-scenarios.md) — How features combine for different requirements
- [Secure Dataplane Overview](secure-dataplane.md) — Three-layer security architecture
