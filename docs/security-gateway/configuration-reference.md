# Security Gateway Configuration Reference

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

This page provides a consolidated reference for all Security Gateway configuration fields. For detailed explanations and examples, see the linked feature pages. For the full REST API documentation, see the [API Reference](../reference/api.md).

## OPA Watcher Configuration

**Endpoint:** `POST /config/opa/watcher`
**Detail page:** [OPA Policy Enforcement](opa-policy-enforcement.md)

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `opa_url` | string | Any HTTP/HTTPS URL | (required) | OPA server URL | [OPA Policy Enforcement](opa-policy-enforcement.md) |
| `policy_path` | string | OPA policy path string | `"loxilb/l4"` | Rego package path to query | [OPA Policy Enforcement](opa-policy-enforcement.md) |
| `poll_interval_sec` | int | `> 0` (integer) | `30` | Seconds between policy fetches | [OPA Policy Enforcement](opa-policy-enforcement.md) |
| `fail_open` | bool | `true`, `false` | `false` | Allow traffic when OPA unreachable | [OPA Policy Enforcement](opa-policy-enforcement.md) |
| `initial_delay_sec` | int | `>= 0` (integer) | `10` | Seconds before first poll | [OPA Policy Enforcement](opa-policy-enforcement.md) |
| `loxilb_url` | string | Any HTTP/HTTPS URL | `"http://localhost:11111"` | loxilb REST API base URL | [OPA Policy Enforcement](opa-policy-enforcement.md) |
| `state_path` | string | File system path | `""` | File path for watcher state persistence | [OPA Policy Enforcement](opa-policy-enforcement.md) |

## LlamaFirewall Configuration

**Endpoint:** `POST /config/llamafirewall/enable`, `POST /config/llamafirewall/scanners`
**Detail page:** [LlamaFirewall](llamafirewall.md)

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `server_url` | string | `host:port` | `"localhost:50052"` | LlamaFirewall gRPC endpoint | [LlamaFirewall](llamafirewall.md) |
| `timeout_sec` | int | `> 0` (integer) | `15` | gRPC call timeout | [LlamaFirewall](llamafirewall.md) |
| `fail_closed` | int | `0`, `1` | `0` | 0=fail-open, 1=fail-closed | [LlamaFirewall](llamafirewall.md) |
| `block_threshold` | float | `0.0`–`1.0` | `0.9` | Score threshold for blocking | [LlamaFirewall](llamafirewall.md) |
| `cache_ttl` | int | `> 0` (seconds) | `300` | Cache TTL in seconds | [LlamaFirewall](llamafirewall.md) |
| `connection_pool_size` | int | `> 0` (integer) | `10` | gRPC connection pool size | [LlamaFirewall](llamafirewall.md) |
| `prompt_guard` | bool | `true`, `false` | `true` | Enable prompt injection scanner | [LlamaFirewall](llamafirewall.md) |
| `code_shield` | bool | `true`, `false` | `true` | Enable code vulnerability scanner | [LlamaFirewall](llamafirewall.md) |
| `regex` | bool | `true`, `false` | `true` | Enable regex credential scanner | [LlamaFirewall](llamafirewall.md) |
| `hidden_ascii` | bool | `true`, `false` | `true` | Enable hidden character scanner | [LlamaFirewall](llamafirewall.md) |
| `agent_alignment` | bool | `true`, `false` | `false` | Enable agent misalignment scanner | [LlamaFirewall](llamafirewall.md) |
| `pii_detection` | bool | `true`, `false` | `false` | Enable PII detection scanner | [LlamaFirewall](llamafirewall.md) |

## Presidio Configuration

**Endpoint:** `POST /config/pii/enable`, `POST /config/pii/configure`
**Detail page:** [Presidio PII Detection](presidio-pii-detection.md)

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `presidio_url` | string | Any HTTP/HTTPS URL | (required) | Presidio Analyzer endpoint | [Presidio PII Detection](presidio-pii-detection.md) |
| `score_threshold` | float | `0.0`–`1.0` | `0.7` | Minimum confidence for PII detection | [Presidio PII Detection](presidio-pii-detection.md) |
| `entities` | string[] | PII entity type names | All entities | PII entity types to detect | [Presidio PII Detection](presidio-pii-detection.md) |
| `action` | string | `"redact"`, `"mask"`, `"log"` | `"redact"` | Action when PII detected | [Presidio PII Detection](presidio-pii-detection.md) |
| `direction` | string | `"request"`, `"response"`, `"both"` | `"request"` | Scan direction | [Presidio PII Detection](presidio-pii-detection.md) |
| `fail_mode` | string | `"open"`, `"closed"` | (configurable) | Behavior when Presidio unreachable | [Presidio PII Detection](presidio-pii-detection.md) |

## Rate Limiting Configuration

**Endpoint:** `POST /config/ai/apikey` (rate limits are part of API key creation)
**Detail page:** [Rate Limiting](rate-limiting.md)

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `rate_limit_rps` | int | `> 0` (requests/sec) | — | Sustained requests per second per key | [Rate Limiting](rate-limiting.md) |
| `burst_size` | int | `> 0` (requests) | — | Maximum burst capacity (bucket size) | [Rate Limiting](rate-limiting.md) |
| `daily_token_quota` | int | `> 0` (tokens) | — | LLM token quota per day per key | [Rate Limiting](rate-limiting.md) |
| `concurrent_limit` | int | `> 0` (connections) | — | Maximum concurrent requests per key | [Rate Limiting](rate-limiting.md) |

## SecurityRateConfig (SYN Flood + Connection Rate + UDP)

**Endpoint:** `POST /config/securityrate`
**Detail page:** [SYN Flood Protection](syn-flood.md)

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `synEnabled` | bool | `true`, `false` | `false` | Enable SYN flood protection | [SYN Flood Protection](syn-flood.md) |
| `synThreshold` | int | `> 0` (packets/sec) | — | SYN packets/sec threshold | [SYN Flood Protection](syn-flood.md) |
| `cookieThreshold` | int | `> 0` (cookies/sec) | — | SYN cookie activation threshold | [SYN Flood Protection](syn-flood.md) |
| `connRateEnabled` | bool | `true`, `false` | `false` | Enable connection rate limiting | [SYN Flood Protection](syn-flood.md) |
| `ratePerSec` | int | `> 0` (connections/sec) | — | Max new connections/sec | [SYN Flood Protection](syn-flood.md) |
| `concurrentLimit` | int | `> 0` (connections) | — | Max concurrent connections | [SYN Flood Protection](syn-flood.md) |
| `udpEnabled` | bool | `true`, `false` | `false` | Enable UDP flood protection | [SYN Flood Protection](syn-flood.md) |
| `udpPktThreshold` | int | `> 0` (packets/sec) | — | UDP packets/sec threshold | [SYN Flood Protection](syn-flood.md) |
| `udpBandwidthMB` | int | `> 0` (MB/s) | — | UDP bandwidth limit (MB/s) | [SYN Flood Protection](syn-flood.md) |
| `whitelistIps` | string[] | Array of CIDR strings | `[]` | CIDRs exempt from all rate controls | [SYN Flood Protection](syn-flood.md) |

## IP Filter Configuration

**Endpoint:** `POST /config/ipfilter`
**Detail page:** [IP Filtering](ip-filtering.md)

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `filterType` | string | `"whitelist"`, `"blacklist"` | (required) | Filter list type | [IP Filtering](ip-filtering.md) |
| `cidr` | string | CIDR notation | (required) | IP range to filter | [IP Filtering](ip-filtering.md) |
| `zone` | int | `0` to N (integer) | `0` | Filtering zone | [IP Filtering](ip-filtering.md) |
| `priority` | int | `0`–`999` (integer) | — | Rule priority (lower = higher precedence) | [IP Filtering](ip-filtering.md) |
| `action` | string | `"allow"`, `"drop"` | (required) | Action when rule matches | [IP Filtering](ip-filtering.md) |

## IPsec Global Configuration

**Endpoint:** `POST /config/ipsec`
**Detail page:** [IPsec Configuration](ipsec.md)

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `fast_path_enabled` | bool | `true`, `false` | `true` | Enable fast path | [IPsec Configuration](ipsec.md) |
| `hw_offload_enabled` | bool | `true`, `false` | `false` | QAT/DPAA2 crypto offload | [IPsec Configuration](ipsec.md) |
| `anti_replay_enabled` | bool | `true`, `false` | `true` | Anti-replay protection | [IPsec Configuration](ipsec.md) |
| `sa_lifetime_warn_seconds` | int | `> 0` (seconds) | `300` | SA expiry warning threshold | [IPsec Configuration](ipsec.md) |
| `mtu` | int | `> 0` (bytes) | `1400` | IPsec tunnel MTU | [IPsec Configuration](ipsec.md) |

## IPsec Tunnel Configuration

**Endpoint:** `POST /config/ipsec/tunnels`
**Detail page:** [IPsec Configuration](ipsec.md)

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `name` | string | Any unique string | (required) | Unique tunnel identifier | [IPsec Configuration](ipsec.md) |
| `local_ip` | string | IPv4 address | (required) | Local endpoint IP | [IPsec Configuration](ipsec.md) |
| `remote_ip` | string | IPv4 address | (required) | Remote endpoint IP | [IPsec Configuration](ipsec.md) |
| `auth_method` | string | `"psk"`, `"cert"` | (required) | Authentication method | [IPsec Configuration](ipsec.md) |
| `ike_version` | int | `1`, `2` | `2` | IKE version | [IPsec Configuration](ipsec.md) |
| `encryption` | string | `"aes128"`, `"aes256"`, `"3des"` | `"aes256"` | IKE encryption algorithm | [IPsec Configuration](ipsec.md) |
| `integrity` | string | `"sha256"`, `"sha384"`, `"sha512"` | `"sha256"` | IKE integrity algorithm | [IPsec Configuration](ipsec.md) |
| `dh_group` | string | `"modp1024"`, `"modp2048"`, `"modp4096"` | `"modp2048"` | IKE DH group | [IPsec Configuration](ipsec.md) |
| `esp_encryption` | string | `"aes128"`, `"aes256"`, `"3des"` | `"aes256"` | ESP encryption algorithm | [IPsec Configuration](ipsec.md) |
| `esp_integrity` | string | `"sha256"`, `"sha384"`, `"sha512"` | `"sha256"` | ESP integrity algorithm | [IPsec Configuration](ipsec.md) |
| `tunnel_mode` | string | `"tunnel"`, `"transport"` | `"tunnel"` | IPsec mode | [IPsec Configuration](ipsec.md) |
| `auto` | string | `"start"`, `"add"`, `"route"` | `"start"` | Auto-initiation mode | [IPsec Configuration](ipsec.md) |

## mTLS Frontend Configuration

**Config mechanism:** Part of load balancer rule (`mtls_frontend` field)
**Detail page:** [mTLS Configuration](mtls.md)

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `client_cert_mode` | string | `"disabled"`, `"optional"`, `"required"` | `"disabled"` | Client certificate requirement | [mTLS Configuration](mtls.md) |
| `client_ca_path` | string | File system path | — | CA for validating client certs | [mTLS Configuration](mtls.md) |
| `client_ca_cert_data` | string | PEM-encoded certificate | — | Inline CA certificate | [mTLS Configuration](mtls.md) |
| `require_client_cn` | bool | `true`, `false` | `false` | Enforce CN matching | [mTLS Configuration](mtls.md) |
| `client_cn_pattern` | string | Glob pattern | — | Pattern for allowed CNs | [mTLS Configuration](mtls.md) |

## mTLS Backend Configuration

**Config mechanism:** Part of load balancer rule (`mtls_backend` field)
**Detail page:** [mTLS Configuration](mtls.md)

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `verify_server_cert` | bool | `true`, `false` | `false` | Validate backend cert | [mTLS Configuration](mtls.md) |
| `backend_ca_path` | string | File system path | — | CA for verifying backend certs | [mTLS Configuration](mtls.md) |
| `client_cert_path` | string | File system path | — | Client cert for backend auth | [mTLS Configuration](mtls.md) |
| `client_key_path` | string | File system path | — | Client key for backend auth | [mTLS Configuration](mtls.md) |
| `client_cert_data` | string | PEM-encoded certificate | — | Inline client certificate | [mTLS Configuration](mtls.md) |
| `client_key_data` | string | PEM-encoded key | — | Inline client key | [mTLS Configuration](mtls.md) |

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
| `/config/pii/enable` | POST | Enable PII detection |
| `/config/pii/configure` | POST | Configure PII detection |
| `/config/pii/status` | GET | PII detection status |
| `/config/llamafirewall/enable` | POST | Enable LlamaFirewall |
| `/config/llamafirewall/scanners` | POST | Configure scanners |
| `/config/llamafirewall/status` | GET | LlamaFirewall status |
| `/config/securityrate` | POST / GET | Unified SYN flood + connection rate + UDP flood |
| `/config/synflood` | POST | Legacy SYN flood (use securityrate instead) |
| `/config/ipfilter` | POST / DELETE | IP filter rule management |
| `/config/ipfilter/all` | GET | List all IP filter rules with counters |
| `/config/ipsec` | POST | IPsec global configuration |
| `/config/ipsec/tunnels` | POST / DELETE | IPsec tunnel management |
| `/config/ipsec/tunnels/all` | GET | List all tunnels |
| `/config/ipsec/certificates` | POST / DELETE | IPsec certificate management |
| `/netlox/v1/config/loadbalancer/{name}` | PUT | Load balancer rule (contains mTLS fields) |

## See Also

- [Full API Reference](../reference/api.md) — Complete REST API documentation
- [Security Gateway Overview](overview.md) — Architecture diagram, fail-mode table
- [Deployment Scenarios](deployment-scenarios.md) — How features combine for different requirements
