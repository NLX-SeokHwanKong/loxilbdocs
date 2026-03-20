# Security Gateway Overview

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is the Security Gateway?

loxilb-enterprise provides a **unified security control plane** at the gateway layer. Instead of scattering security logic across applications, the Security Gateway enforces network policy, data protection, and encrypted transport at a single enforcement point — the eBPF-accelerated data plane.

The Security Gateway organizes its capabilities into three pillars:

- **Policy Enforcement** — OPA-driven L4 firewall rules, rate limiting, SYN flood protection, and IP filtering. These features control who can access what, how fast, and from where.
- **Data Protection** — Presidio PII detection/redaction and LlamaFirewall AI content safety. These features inspect traffic content for sensitive data and malicious AI prompts before it reaches backends.
- **Secure Transport** — IPsec tunnels, mTLS mutual authentication, and eBPF kernel-level protections. These features encrypt and authenticate traffic between nodes and services.

For security architects evaluating loxilb-enterprise, this page serves as the starting point. Each pillar links to detailed feature pages with REST API configuration examples.

## Security Gateway Architecture

The following diagram shows how an incoming request flows through the Security Gateway's full inspection pipeline. Each layer can independently accept, reject, or modify traffic.

```mermaid
flowchart TD
    A[Incoming Request] --> B{eBPF Kernel Layer}
    B -->|SYN flood check| C{SYN Rate OK?}
    C -->|No: exceeds synThreshold| DROP1[DROP: 503]
    C -->|Yes| D{IP Filter Check}
    D -->|Blacklisted IP| DROP2[DROP: 403]
    D -->|Allowed IP| E{Connection Rate Check}
    E -->|Exceeds ratePerSec / concurrentLimit| DROP3[DROP: 429]
    E -->|Within limits| F[L4 Policy Engine]

    F --> G{OPA Firewall Rules}
    G -->|Deny rule matched| DROP4[DROP: 403]
    G -->|Allow / no rule| H{API Key Validation}
    H -->|Invalid key| DROP5[DROP: 401/403]
    H -->|Valid key| I{Per-Key RPS Check}
    I -->|Exceeds rate_limit_rps| DROP6[DROP: 429 + Retry-After]
    I -->|Within limit| J[L7 Content Inspection]

    J --> K{Presidio PII Scan}
    K -->|PII detected: action=block| DROP7[DROP: 403]
    K -->|PII detected: action=redact| L[Redact PII in body]
    K -->|No PII / action=log| M{LlamaFirewall Scan}
    L --> M

    M -->|Threat detected: BLOCK| DROP8[DROP: 403 + X-LlamaFirewall-Decision]
    M -->|ALLOW| N[Backend Services]

    N --> O[Response Path]
    O --> P{Response Scanning}
    P -->|LlamaFirewall response scan| Q{Code/Credential check}
    Q -->|Threat| DROP9[DROP: 403]
    Q -->|Clean| R[Return to Client]

    style DROP1 fill:#ff6b6b,color:#fff
    style DROP2 fill:#ff6b6b,color:#fff
    style DROP3 fill:#ff6b6b,color:#fff
    style DROP4 fill:#ff6b6b,color:#fff
    style DROP5 fill:#ff6b6b,color:#fff
    style DROP6 fill:#ff6b6b,color:#fff
    style DROP7 fill:#ff6b6b,color:#fff
    style DROP8 fill:#ff6b6b,color:#fff
    style DROP9 fill:#ff6b6b,color:#fff
    style N fill:#51cf66,color:#fff
    style R fill:#51cf66,color:#fff
```

Traffic passes through layers in a strict order: kernel-level eBPF filtering first (fastest, drops obvious network-layer attacks), then L4 policy enforcement (OPA rules, API key validation, per-key rate limits), then L7 content inspection (Presidio PII detection, LlamaFirewall AI safety). Each layer can independently drop or modify traffic before it reaches the next.

## Deep Internals

The Security Gateway pipeline is implemented in C within the sockproxy subsystem. Understanding the execution order helps operators reason about where security decisions happen and what fields each layer inspects.

### Request Processing Order in sockproxy_http.c

When a complete HTTP request arrives at the sockproxy data plane (`sockproxy_http.c`), security checks execute in this order:

1. **eBPF kernel checks** (sockproxy_conn.c) — SYN flood protection, connection rate limiting, UDP flood protection, and IP filtering execute in the kernel fast path via eBPF programs. These checks happen before any userspace processing and add near-zero latency to allowed traffic.

2. **AI Gateway enforcement** (sockproxy_http.c, line ~4489) — When `ai_gw_mode` is enabled on a service rule, the gateway validates the `X-Api-Key` header via `llb_ai_validate_key()`. Invalid keys receive 401; model-denied keys receive 403. Valid keys proceed to per-key and per-tenant RPS checking via `llb_ai_ratelimit_check()`, which returns a `retry_after` value on 429 rejection.

3. **Presidio PII scanning** (sockproxy_http.c, line ~4555) — If `HAVE_PII_DETECTION` is compiled in and `pii_cfg->enabled` is true, the gateway extracts the HTTP body, checks URL patterns against the configured include/exclude list, and sends the body to the Presidio analyzer via gRPC. PII masking is **deferred** — the masked text is stored in `ent->pii_masked_text` and applied later in `proxy_try_epxmit()` to avoid modifying the receive buffer mid-parse.

4. **LlamaFirewall scanning** (sockproxy_http.c, line ~4700) — If `HAVE_LLAMAFIREWALL` is compiled in and `llamafirewall_is_initialized()` returns true, the gateway scans the request content. The architecture is: Presidio masks PII first, then LlamaFirewall blocks attacks, then the backend processes safe content. If LlamaFirewall returns `DECISION_BLOCK`, the gateway sends a 403 response with `X-LlamaFirewall-Decision: BLOCK` header.

### Circuit Breaker Pattern

Both Presidio and LlamaFirewall implement identical circuit breaker patterns (three-state: CLOSED, OPEN, HALF_OPEN) to prevent cascading failures when external scanning services go down. The circuit breaker:

- **CLOSED** (normal): Every request is scanned. Consecutive failures increment a counter.
- **OPEN** (service down): Scanning is bypassed. The fail mode (`fail_open` or `fail_closed`) determines whether traffic is allowed or blocked. After `circuit_breaker_timeout_sec` seconds, transitions to HALF_OPEN.
- **HALF_OPEN** (testing): A single request is sent to the service. Success closes the circuit; failure reopens it.

This pattern ensures that a Presidio or LlamaFirewall outage does not cause the entire gateway to hang on timeout — the circuit opens after the configured failure threshold and recovers automatically.

### Deferred PII Masking

A notable implementation detail is that Presidio PII masking is **deferred** rather than applied immediately. When Presidio detects PII, the masked text is stored in `ent->pii_masked_text` with a flag `ent->pii_needs_masking = 1`. The actual body replacement happens later in `proxy_try_epxmit()` (sockproxy_http.c, line ~499), where:

1. The masked body length is compared to the original
2. The `Content-Length` header is adjusted via in-place memmove if lengths differ
3. The masked text is memcpy'd over the original body
4. Statistics are updated (`[PII_APPLIED]` log entry)

This deferred approach avoids modifying the receive buffer mid-parse, which would corrupt HTTP header parsing for subsequent pipeline stages (LlamaFirewall scanning uses the same buffer).

### Integration Between Security Gateway and AI Gateway

When both the Security Gateway and AI Gateway are enabled on the same service rule (`ai_gw_mode=1`), the security pipeline executes within the AI Gateway's request processing. The order is:

1. AI Gateway validates `X-Api-Key` header
2. AI Gateway enforces per-key and per-tenant RPS limits
3. Security Gateway runs Presidio PII scan on the request body
4. Security Gateway runs LlamaFirewall threat scan on the (possibly PII-masked) content
5. AI Gateway selects the backend endpoint and forwards the safe request

This means Security Gateway content inspection only runs on requests that have already passed API key validation and rate limiting — reducing unnecessary scanning of unauthorized or rate-limited requests.

### Shared Memory Configuration

Presidio and LlamaFirewall use a **shared memory hot-reload pattern** for configuration. Configuration written via the REST API is stored at `/dev/shm/loxilb_presidio_config` (Presidio) and a similar path for LlamaFirewall. The C data plane reads configuration from shared memory on each request via `presidio_config_get()` and `llamafirewall_config_get()`, enabling zero-downtime reconfiguration without restarting the proxy.

Key shared memory configuration fields include:

- **Presidio**: `enabled`, `analyzer_url`, `anonymizer_url`, `mode`, `direction`, `score_threshold`, `timeout_ms`, `min_body_size`, `max_body_size`, `scan_mode` (FULL or TRUNCATE), `fail_mode` (FAIL_OPEN or FAIL_CLOSED), URL patterns for selective scanning
- **LlamaFirewall**: `server_url`, `enabled`, `fail_closed`, `scanner_mask`, `block_threshold`

## Feature Overview Table

| Feature | Pillar | Source File | Key Config Field | Default | Reference |
|---------|--------|------------|------------------|---------|-----------|
| SYN Flood Protection | Policy | sockproxy_conn.c (eBPF) | `synThreshold` | `100` SYN/s per IP | [SYN Flood](syn-flood.md) |
| IP Filtering | Policy | sockproxy_conn.c (eBPF) | `whitelistIps` | empty | [IP Filtering](ip-filtering.md) |
| Connection Rate Limiting | Policy | sockproxy_conn.c (eBPF) | `ratePerSec` | `50` conn/s per IP | [Rate Limiting](rate-limiting.md) |
| OPA Policy Enforcement | Policy | Go OPA watcher | `opa_url`, `policy_path` | `loxilb/l4` | [OPA](opa-policy-enforcement.md) |
| Per-Key RPS Limiting | Policy | sockproxy_http.c | `rate_limit_rps`, `burst_size` | per-key | [Rate Limiting](rate-limiting.md) |
| Presidio PII Detection | Data Protection | sockproxy_presidio.c | `presidio_url`, `score_threshold` | `0.7` | [Presidio](presidio-pii-detection.md) |
| LlamaFirewall AI Safety | Data Protection | sockproxy_llamafirewall.c | `server_url`, `fail_closed` | `0` (fail-open) | [LlamaFirewall](llamafirewall.md) |
| IPsec Tunnels | Transport | strongSwan integration | `authMode`, `ikeVersion` | `ikev2` | [IPsec](ipsec.md) |
| mTLS | Transport | sockproxy_ssl.c | per-LB rule config | — | [mTLS](mtls.md) |

## REST API Configuration

The Security Gateway exposes its features through the following REST API endpoint groups:

| Feature | API Endpoint | Method | Reference |
|---------|-------------|--------|-----------|
| OPA Policy Watcher | `/config/opa/watcher` | POST/GET/DELETE | [API Reference](../reference/api.md#opa-policy-watcher) |
| PII Detection (Presidio) | `/config/pii/configure` | POST | [API Reference](../reference/api.md#pii-detection-presidio) |
| LlamaFirewall | `/config/llamafirewall/enable` | POST | [API Reference](../reference/api.md#llamafirewall) |
| Security Rate Limiting | `/config/securityrate` | POST/DELETE | [API Reference](../reference/api.md#security-controls) |
| IPsec Global Config | `/config/ipsec` | GET/PUT | [API Reference](../reference/api.md#ipsec) |
| IPsec Tunnels | `/config/ipsec/tunnels` | POST/GET/DELETE | [API Reference](../reference/api.md#ipsec) |
| IPsec Certificates | `/config/ipsec/certificates` | POST/GET/DELETE | [API Reference](../reference/api.md#ipsec) |
| IP Filtering | `/config/ipfilter` | POST | [API Reference](../reference/api.md#security-controls) |
| SNI/mTLS Certificates | `PUT /config/loadbalancer/{name}` | PUT | [API Reference](../reference/api.md#sni-certificates) |

## Fail Mode Reference

!!! warning "Verify fail mode settings before production deployment"
    OPA defaults to **fail-closed** while LlamaFirewall defaults to **fail-open**. These opposite defaults reflect different security philosophies — access control blocks by default, content scanning preserves availability by default. Confirm that fail mode settings match your organization's security policy.

| Component | Default Fail Mode | Behavior When Service Down | Config Field | Circuit Breaker |
|-----------|-------------------|---------------------------|--------------|-----------------|
| OPA Watcher | **Fail-closed** | No new firewall rules installed; existing rules remain | `fail_open: false` | 3-state (CLOSED/OPEN/HALF_OPEN) |
| LlamaFirewall | **Fail-open** | Traffic passes without AI safety scan | `fail_closed: 0` | 3-state with configurable threshold |
| Presidio | **Configurable** | Depends on `fail_mode` setting (`FAIL_OPEN` or `FAIL_CLOSED`) | `fail_mode` | 3-state with retry logic |

### Circuit Breaker Configuration

Both Presidio and LlamaFirewall circuit breakers are configurable via shared memory:

| Parameter | Presidio Default | LlamaFirewall Default | Description |
|-----------|-----------------|----------------------|-------------|
| `circuit_breaker_threshold` | `5` failures | `5` failures | Consecutive failures to open circuit |
| `circuit_breaker_timeout_sec` | `60` seconds | `60` seconds | Time in OPEN state before testing recovery |
| `circuit_breaker_success_threshold` | `3` successes | `3` successes | Consecutive successes in HALF_OPEN to close circuit |

## Port Allocation

When deploying multiple security services, ensure no port conflicts:

| Service | Default Port | Protocol | Config Location |
|---------|-------------|----------|-----------------|
| OPA Server | 8181 | HTTP | `opa_url` in watcher config |
| Presidio Analyzer | 50051 | gRPC | `analyzer_url` in Presidio config |
| Presidio Anonymizer | (separate) | gRPC | `anonymizer_url` in Presidio config |
| LlamaFirewall | 50052 | gRPC | `server_url` in LlamaFirewall config |

## Deployment Scenarios

### Scenario 1: Full Security Stack for AI/LLM Traffic

Deploy all content inspection layers for maximum protection of AI workloads. This configuration protects against network-layer attacks, enforces per-key quotas, detects PII in prompts, and blocks prompt injection and malicious content.

```bash
# 1. Enable SYN flood + connection rate protection
curl -X POST http://loxilb:11111/netlox/v1/config/securityrate \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "synEnabled": true,
    "synThreshold": 100,
    "cookieThreshold": 50,
    "connRateEnabled": true,
    "ratePerSec": 200,
    "concurrentLimit": 500,
    "udpEnabled": false,
    "udpPktThreshold": 0,
    "udpBandwidthMB": 0
  }'

# 2. Configure OPA policy watcher
curl -X POST http://loxilb:11111/netlox/v1/config/opa/watcher \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "opa_url": "http://opa-server:8181",
    "policy_path": "loxilb/l4",
    "poll_interval_sec": 30,
    "fail_open": false
  }'

# 3. Enable Presidio PII detection
curl -X POST http://loxilb:11111/netlox/v1/config/pii/enable \
  -H "Authorization: Bearer <token>"

# 4. Enable LlamaFirewall AI safety
curl -X POST http://loxilb:11111/netlox/v1/config/llamafirewall/enable \
  -H "Authorization: Bearer <token>"
```

**Result:** Every AI request passes through: eBPF flood protection -> OPA firewall rules -> API key + rate limit -> Presidio PII scan -> LlamaFirewall threat scan -> backend LLM.

### Scenario 2: Transport-Only Security for East-West Service Traffic

Deploy IPsec encryption and mTLS authentication for internal service-to-service communication without content inspection. This configuration encrypts all traffic between nodes and validates service identity.

```bash
# 1. Configure IPsec with certificate authentication
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/certificates \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "node-cert",
    "certificate": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----",
    "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
  }'

# 2. Create IPsec tunnel between nodes
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/tunnels \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "node1-to-node2",
    "localIp": "10.1.0.1",
    "remoteIp": "10.2.0.1",
    "authMode": "cert",
    "certName": "node-cert",
    "caCertName": "ca-cert",
    "ikeVersion": "ikev2",
    "ikeEncryption": "aes256-sha256-modp2048",
    "espEncryption": "aes256-sha256",
    "auto": "start"
  }'

# 3. Enable fast-path for performance
curl -X PUT http://loxilb:11111/netlox/v1/config/ipsec \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "fastPathEnabled": true,
    "antiReplayEnabled": true
  }'
```

**Result:** All traffic between nodes is encrypted with AES-256 via IPsec tunnels. Certificate-based authentication ensures only authorized nodes can communicate. Fast-path eBPF bypass minimizes encryption overhead for established SAs.

### Choosing Between Scenarios

| Criteria | Full Security Stack | Transport-Only |
|----------|-------------------|----------------|
| **Use case** | AI/LLM workloads with external clients | Internal service mesh |
| **Latency impact** | Higher (content inspection adds ~5-20ms per scan) | Lower (encryption overhead only) |
| **External dependencies** | OPA server, Presidio, LlamaFirewall containers | strongSwan only |
| **Compliance** | GDPR, CCPA, SOC2 (content inspection) | HIPAA, PCI-DSS (encryption in transit) |
| **Configuration complexity** | High — multiple services to deploy and configure | Moderate — tunnel and certificate management |

For deployments requiring both content inspection and transport encryption (e.g., AI traffic between data centers), combine both scenarios: use the full security stack for inbound client traffic and IPsec tunnels for inter-node backend communication.

## Feature Pages

### Policy Enforcement

- **[OPA Policy Enforcement](opa-policy-enforcement.md)** — Write Rego policies that translate to L4 firewall rules. Centralized policy management with GitOps-compatible workflow.
- **[Rate Limiting](rate-limiting.md)** — Per-key RPS/burst limits and per-key token quotas for AI inference cost control. Token-bucket algorithm at the gateway layer.
- **[SYN Flood Protection](syn-flood.md)** — eBPF-level DDoS mitigation with unified API for SYN flood, connection rate, and UDP flood protection.
- **[IP Filtering](ip-filtering.md)** — IP-based access control with whitelist/blacklist modes, enforced in the kernel fast path before any application processing.

### Data Protection

- **[Presidio PII Detection](presidio-pii-detection.md)** — Gateway-layer PII detection and redaction for GDPR/CCPA compliance. Supports replace, redact, hash, encrypt, and mask operators with per-entity configuration.
- **[LlamaFirewall AI Safety](llamafirewall.md)** — AI content safety scanning for prompt injection, jailbreak attempts, insecure code, and credential leakage. Six configurable scanner types with circuit breaker resilience.

### Secure Transport

- **[Secure Dataplane Overview](secure-dataplane.md)** — Architectural comparison of IPsec, mTLS, and eBPF security layers with decision guide for choosing the right approach.
- **[IPsec Configuration](ipsec.md)** — L3 tunnel encryption between nodes using strongSwan integration. Supports PSK and X.509 certificate authentication with hardware offload.
- **[mTLS Configuration](mtls.md)** — Mutual TLS authentication per load balancer rule in FullProxy mode. Frontend client cert validation and backend server cert verification.

### Operations

- **[Deployment Scenarios](deployment-scenarios.md)** — Four deployment patterns showing how Security Gateway features combine for different compliance requirements.
- **[Configuration Reference](configuration-reference.md)** — Cross-feature quick-reference table with all config fields and defaults.

## Verify

Confirm the Security Gateway is operational by checking the status of configured features:

```bash
# Check OPA watcher status
curl http://loxilb:11111/netlox/v1/config/opa/watcher \
  -H "Authorization: Bearer <token>"

# Check LlamaFirewall status
curl http://loxilb:11111/netlox/v1/config/llamafirewall/status \
  -H "Authorization: Bearer <token>"

# Check PII detection status
curl http://loxilb:11111/netlox/v1/config/pii/status \
  -H "Authorization: Bearer <token>"

# Check security rate limiting status
curl http://loxilb:11111/netlox/v1/config/securityrate/all \
  -H "Authorization: Bearer <token>"

# Check IPsec tunnels
curl http://loxilb:11111/netlox/v1/config/ipsec/tunnels/all \
  -H "Authorization: Bearer <token>"
```

Each endpoint returns the current configuration and health status of its respective feature. See individual feature pages for expected response details.

## See Also

- [Full API Reference](../reference/api.md) — Complete REST API documentation
- [AI Gateway Overview](../ai-gateway/overview.md) — AI Gateway features that complement Security Gateway data protection
- [Getting Started](../getting-started/installation.md) — Enterprise binary installation and initial setup
