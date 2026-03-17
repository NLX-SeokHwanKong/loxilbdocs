# Security Gateway Configuration Reference

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

This page provides a consolidated reference for all Security Gateway configuration fields. For detailed explanations and examples, see the linked feature pages.

## OPA Watcher Configuration

**Endpoint:** `POST /config/opa/watcher`
**Detail page:** [OPA Policy Enforcement](opa-policy-enforcement.md)

| Field | Type | Default | Description | Source |
|-------|------|---------|-------------|--------|
| `opa_url` | string | (required) | OPA server URL | `pkg/opa/watcher.go:37` |
| `policy_path` | string | `"loxilb/l4"` | Rego package path to query | `pkg/opa/watcher.go:33` |
| `poll_interval_sec` | int | `30` | Seconds between policy fetches | `pkg/opa/watcher.go:42` |
| `fail_open` | bool | `false` | Allow traffic when OPA unreachable | `pkg/opa/watcher.go:48` |
| `initial_delay_sec` | int | `10` | Seconds before first poll | `pkg/opa/watcher.go` |
| `loxilb_url` | string | `"http://localhost:11111"` | loxilb REST API base URL | `pkg/opa/watcher.go` |
| `state_path` | string | `""` | File path for watcher state persistence | `pkg/opa/watcher.go` |

## LlamaFirewall Configuration

**Endpoint:** Inline configuration via AI Gateway
**Detail page:** [LlamaFirewall](llamafirewall.md)

| Field | Type | Default | Description | Source |
|-------|------|---------|-------------|--------|
| `server_url` | string | `"localhost:50052"` | LlamaFirewall gRPC endpoint | `pkg/llamafirewall/config.go` |
| `timeout_sec` | int | `15` | gRPC call timeout | `pkg/llamafirewall/config.go` |
| `fail_closed` | int | `0` | 0=fail-open, 1=fail-closed | `pkg/llamafirewall/config.go` |
| `block_threshold` | float | `0.9` | Score threshold for blocking | `pkg/llamafirewall/config.go` |
| `cache_ttl` | int | `300` | Cache TTL in seconds | `pkg/llamafirewall/config.go` |
| `connection_pool_size` | int | `10` | gRPC connection pool size | `pkg/llamafirewall/config.go` |
| `prompt_guard` | bool | `true` | Enable prompt injection scanner | `pkg/llamafirewall/config.go` |
| `code_shield` | bool | `true` | Enable code vulnerability scanner | `pkg/llamafirewall/config.go` |
| `regex` | bool | `true` | Enable regex credential scanner | `pkg/llamafirewall/config.go` |
| `hidden_ascii` | bool | `true` | Enable hidden character scanner | `pkg/llamafirewall/config.go` |
| `agent_alignment` | bool | `false` | Enable agent misalignment scanner | `pkg/llamafirewall/config.go` |
| `pii_detection` | bool | `false` | Enable PII detection scanner | `pkg/llamafirewall/config.go` |

## Presidio Configuration

**Config mechanism:** Shared memory at `/dev/shm/loxilb_presidio_config` (no REST endpoint)
**Detail page:** [Presidio PII Detection](presidio-pii-detection.md)

| Field | Type | Default | Description | Source |
|-------|------|---------|-------------|--------|
| `analyzer_addr` | string | `"presidio-analyzer:50051"` | Presidio Analyzer gRPC endpoint | `pkg/presidio/config.go` |
| `mode` | string | `"detect"` | Operation mode: detect/mask/redact/anonymize | `pkg/presidio/config.go` |
| `direction` | string | `"both"` | Scan direction: both/request/response | `pkg/presidio/config.go` |
| `fail_mode` | string | (configurable) | Behavior when Presidio unreachable | `pkg/presidio/config.go` |
| `scan_mode` | string | — | Scanning strategy | `pkg/presidio/config.go` |
| `score_threshold` | float | — | Minimum confidence for PII detection | `pkg/presidio/config.go` |

## Rate Limiting Configuration

**Config mechanism:** Part of API key creation
**Detail page:** [Rate Limiting](rate-limiting.md)

| Field | Type | Default | Description | Source |
|-------|------|---------|-------------|--------|
| `rate_limit_rps` | int | — | Sustained requests per second per key | `pkg/user/api_key.go:37-55` |
| `burst_size` | int | — | Maximum burst capacity (bucket size) | `pkg/user/api_key.go:37-55` |
| `tokens_per_min` | int | — | LLM token quota per minute per key | `pkg/user/api_key.go:37-55` |

## SecurityRateConfig (SYN Flood + Connection Rate + UDP)

**Endpoint:** `POST /config/securityrate`
**Detail page:** [SYN Flood Protection](syn-flood.md)

| Field | Type | Default | Description | Source |
|-------|------|---------|-------------|--------|
| `synEnabled` | bool | — | Enable SYN flood protection | `common/common.go:534` |
| `synThreshold` | int | — | SYN packets/sec threshold | `common/common.go:534` |
| `cookieThreshold` | int | — | SYN cookie activation threshold | `common/common.go:534` |
| `connRateEnabled` | bool | — | Enable connection rate limiting | `common/common.go:534` |
| `ratePerSec` | int | — | Max new connections/sec | `common/common.go:534` |
| `concurrentLimit` | int | — | Max concurrent connections | `common/common.go:534` |
| `udpEnabled` | bool | — | Enable UDP flood protection | `common/common.go:534` |
| `udpPktThreshold` | int | — | UDP packets/sec threshold | `common/common.go:534` |
| `udpBandwidthMB` | int | — | UDP bandwidth limit (MB/s) | `common/common.go:534` |
| `whitelistIps` | string[] | `[]` | CIDRs exempt from all rate controls | `common/common.go:534` |

## IP Filter Configuration

**Endpoint:** `POST /config/ipfilter`
**Detail page:** [IP Filtering](ip-filtering.md)

| Field | Type | Default | Description | Source |
|-------|------|---------|-------------|--------|
| `filterType` | string | — | `"whitelist"` or `"blacklist"` | `common/common.go:465` |
| `cidr` | string | — | IP range in CIDR notation | `common/common.go:465` |
| `zone` | int | `0` | Filtering zone | `common/common.go:465` |
| `priority` | int | — | Rule priority (higher = first) | `common/common.go:465` |
| `action` | string | — | `"allow"` or `"drop"` | `common/common.go:465` |

## IPsec Global Configuration

**Endpoint:** `POST /config/ipsec`
**Detail page:** [IPsec Configuration](ipsec.md)

| Field | Type | Default | Description | Source |
|-------|------|---------|-------------|--------|
| `fastPathEnabled` | bool | `true` | Enable fast path | `common/common.go:1563` |
| `hwOffloadEnabled` | bool | `false` | QAT/DPAA2 crypto offload | `common/common.go:1563` |
| `antiReplayEnabled` | bool | `true` | Anti-replay protection | `common/common.go:1563` |
| `saLifetimeWarnSeconds` | int | `300` | SA expiry warning threshold | `common/common.go:1563` |
| `mtu` | int | `1400` | IPsec tunnel MTU | `common/common.go:1563` |

## IPsec Tunnel Configuration

**Endpoint:** `POST /config/ipsec/tunnels`
**Detail page:** [IPsec Configuration](ipsec.md)

| Field | Type | Default | Description | Source |
|-------|------|---------|-------------|--------|
| `name` | string | (required) | Unique tunnel identifier | `common/common.go:1602` |
| `localIp` | string | (required) | Local endpoint IP | `common/common.go:1602` |
| `remoteIp` | string | (required) | Remote endpoint IP | `common/common.go:1602` |
| `authMode` | string | (required) | `"psk"` or `"cert"` | `common/common.go:1602` |
| `ikeVersion` | string | `"ikev2"` | `"ikev1"` or `"ikev2"` | `common/common.go:1602` |
| `ikeEncryption` | string | `"aes256"` | IKE encryption algorithm | `common/common.go:1602` |
| `ikeIntegrity` | string | `"sha256"` | IKE integrity algorithm | `common/common.go:1602` |
| `ikeDhGroup` | string | `"modp2048"` | IKE DH group | `common/common.go:1602` |
| `espEncryption` | string | `"aes256"` | ESP encryption algorithm | `common/common.go:1602` |
| `espIntegrity` | string | `"sha256"` | ESP integrity algorithm | `common/common.go:1602` |
| `tunnelMode` | string | `"tunnel"` | `"tunnel"` or `"transport"` | `common/common.go:1602` |
| `auto` | string | `"start"` | `"start"`, `"add"`, `"route"` | `common/common.go:1602` |

## mTLS Frontend Configuration

**Config mechanism:** Part of load balancer rule (`mtls_frontend` field)
**Detail page:** [mTLS Configuration](mtls.md)

| Field | Type | Default | Description | Source |
|-------|------|---------|-------------|--------|
| `client_cert_mode` | string | `"disabled"` | `disabled`/`optional`/`required` | `common/common_mtls.go:34` |
| `client_ca_path` | string | — | CA for validating client certs | `common/common_mtls.go:34` |
| `client_ca_cert_data` | string | — | Inline CA certificate | `common/common_mtls.go:34` |
| `require_client_cn` | bool | `false` | Enforce CN matching | `common/common_mtls.go:34` |
| `client_cn_pattern` | string | — | Glob pattern for allowed CNs | `common/common_mtls.go:34` |

## mTLS Backend Configuration

**Config mechanism:** Part of load balancer rule (`mtls_backend` field)
**Detail page:** [mTLS Configuration](mtls.md)

| Field | Type | Default | Description | Source |
|-------|------|---------|-------------|--------|
| `verify_server_cert` | bool | `false` | Validate backend cert | `common/common_mtls.go` |
| `backend_ca_path` | string | — | CA for verifying backend certs | `common/common_mtls.go` |
| `client_cert_path` | string | — | Client cert for backend auth | `common/common_mtls.go` |
| `client_key_path` | string | — | Client key for backend auth | `common/common_mtls.go` |
| `client_cert_data` | string | — | Inline client certificate | `common/common_mtls.go` |
| `client_key_data` | string | — | Inline client key | `common/common_mtls.go` |

## Port Allocation Summary

| Service | Port | Protocol |
|---------|------|----------|
| OPA Server | 8181 | HTTP |
| Presidio Analyzer | 50051 | gRPC |
| LlamaFirewall | 50052 | gRPC |

## REST API Endpoints Summary

| Endpoint | Method | Feature |
|----------|--------|---------|
| `/config/opa/watcher` | POST / GET / DELETE | OPA watcher management |
| `/config/securityrate` | POST | Unified SYN flood + connection rate + UDP flood |
| `/config/synflood` | POST | Legacy SYN flood (use securityrate instead) |
| `/config/ipfilter` | POST / DELETE | IP filter rule management |
| `/config/ipfilter/all` | GET | List all IP filter rules with counters |
| `/config/ipsec` | POST | IPsec global configuration |
| `/config/ipsec/tunnels` | POST / DELETE | IPsec tunnel management |
| `/config/ipsec/certificates` | POST / DELETE | IPsec certificate management |
| `/netlox/v1/config/loadbalancer/{name}` | PUT | Load balancer rule (contains mTLS fields) |

## See Also

- [Security Gateway Overview](overview.md) — Architecture diagram, fail-mode table
- [Deployment Scenarios](deployment-scenarios.md) — How features combine for different requirements
