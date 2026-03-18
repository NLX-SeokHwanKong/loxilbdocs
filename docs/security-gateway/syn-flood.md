# SYN Flood Protection

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is SYN Flood Protection?

SYN flood attacks exhaust server connection tables by sending a flood of TCP SYN packets without completing the three-way handshake. Each half-open connection consumes memory and a slot in the connection table — at sufficient volume, legitimate connections are denied.

loxilb mitigates SYN floods at the **eBPF dataplane level**. Packets are filtered in the kernel TC (Traffic Control) hook before reaching userspace, minimizing CPU overhead during attacks. When the SYN rate exceeds the configured threshold, loxilb activates SYN cookie mode to validate connections without consuming connection table resources.

## Unified Security Rate Control

loxilb provides a **unified SecurityRateConfig API** that manages three related protections through a single endpoint:

| Protection | Prefix | What it Controls |
|-----------|--------|-----------------|
| **SYN Flood** (P0-5) | `syn*` | TCP SYN packet rate, SYN cookie activation |
| **Connection Rate** (P0-6) | `connRate*`, `rate*`, `concurrent*` | New connection rate, max concurrent connections |
| **UDP Flood** (P0-7) | `udp*` | UDP packet rate, bandwidth limit |

All three protections share a `whitelistIps` array — trusted CIDRs that are exempt from all rate controls.

## REST API Configuration

### Unified SecurityRateConfig (Recommended)

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/securityrate \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "synEnabled": true,
    "synThreshold": 100,
    "cookieThreshold": 50,
    "connRateEnabled": true,
    "ratePerSec": 50,
    "concurrentLimit": 200,
    "udpEnabled": false,
    "udpPktThreshold": 1000,
    "udpBandwidthMB": 100,
    "whitelistIps": ["10.0.0.0/8", "172.16.0.0/12"]
  }'

# Response (200): {"result": "Success"}
```

### Field Reference

**SYN Flood Protection (P0-5):**

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `synEnabled` | bool | `true`, `false` | `false` | Enable SYN flood protection |
| `synThreshold` | int | `> 0` (packets/sec) | — | SYN packets/sec before SYN cookie activation |
| `cookieThreshold` | int | `> 0` (cookies/sec) | — | SYN cookies/sec threshold for escalated mitigation |

**Connection Rate Limiting (P0-6):**

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `connRateEnabled` | bool | `true`, `false` | `false` | Enable connection rate limiting |
| `ratePerSec` | int | `> 0` (connections/sec) | — | Maximum new connections per second |
| `concurrentLimit` | int | `> 0` (connections) | — | Maximum concurrent connections |

**UDP Flood Protection (P0-7):**

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `udpEnabled` | bool | `true`, `false` | `false` | Enable UDP flood protection |
| `udpPktThreshold` | int | `> 0` (packets/sec) | — | UDP packets/sec threshold |
| `udpBandwidthMB` | int | `> 0` (MB/s) | — | UDP bandwidth limit in MB/s |

**Shared:**

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `whitelistIps` | string[] | Array of CIDR strings | `[]` | CIDR ranges exempt from all rate controls |

### Legacy SYN Flood API

The older `/config/synflood` endpoint provides SYN-only protection:

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/synflood \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "synThreshold": 100,
    "cookieThreshold": 50,
    "whitelistIps": ["10.0.0.0/8"]
  }'

# Response (200): {"result": "Success"}
```

!!! note "Use the unified API for new deployments"
    The unified `/config/securityrate` endpoint is recommended for all new deployments. It combines SYN flood, connection rate, and UDP flood protection in a single API call. The legacy `/config/synflood` endpoint remains available for backward compatibility.

## How SYN Cookie Mitigation Works

When the SYN rate exceeds `synThreshold`:

1. **Detection:** The eBPF TC hook counts SYN packets per second
2. **Activation:** When the threshold is exceeded, SYN cookie mode activates
3. **Challenge:** Instead of allocating a connection table entry, loxilb sends a SYN-ACK with a cryptographic cookie
4. **Validation:** Only clients that complete the handshake (ACK with valid cookie) get a connection table entry
5. **Recovery:** When the rate drops below threshold, normal operation resumes

This approach means legitimate clients can still connect during an attack — they just need to complete the handshake. Attack traffic (which never sends the ACK) consumes no resources.

## Verify

Confirm security rate configuration is active:

```bash
curl http://loxilb:11111/netlox/v1/config/securityrate/all \
  -H "Authorization: Bearer <token>"

# Response (200):
# [
#   {
#     "synEnabled": true,
#     "synThreshold": 100,
#     "cookieThreshold": 50,
#     "connRateEnabled": true,
#     "ratePerSec": 50,
#     "concurrentLimit": 200,
#     "whitelistIps": ["10.0.0.0/8", "172.16.0.0/12"]
#   }
# ]
```

Check that `synEnabled` is `true` and threshold values match your configuration.

## Troubleshoot

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| SYN flood protection not triggering | `synEnabled` is `false` or `synThreshold` set too high | Verify `synEnabled: true` and adjust `synThreshold` to expected traffic levels |
| Legitimate traffic blocked | Trusted sources not in `whitelistIps` or thresholds too low | Add trusted CIDRs to `whitelistIps`, increase `synThreshold` |
| Connection rate errors for valid clients | `concurrentLimit` too low for workload | Increase `concurrentLimit` and `ratePerSec` values |

## See Also

- [Security Controls API Reference](../reference/api.md#security-controls)
- [IP Filtering](ip-filtering.md) — IP-based access control at the eBPF dataplane level
- [Secure Dataplane Overview](secure-dataplane.md) — How eBPF security fits in the layered architecture
- [Security Gateway Overview](overview.md) — Full Security Gateway feature map
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
