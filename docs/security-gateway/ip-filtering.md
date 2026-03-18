# IP Filtering

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is IP Filtering?

IP filtering provides IP-based access control at the eBPF dataplane level. You can whitelist trusted CIDR ranges or blacklist known-bad IP ranges, and rules are enforced in the **kernel fast path** before any application processing occurs.

This is the first line of defense — packets matching blacklist rules are dropped at the TC hook with minimal CPU overhead. For network administrators, IP filtering provides the equivalent of edge firewall ACLs, but implemented in eBPF for high-throughput environments.

## REST API Configuration

### Adding a Filter Rule

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ipfilter \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "filterType": "blacklist",
    "cidr": "192.0.2.0/24",
    "zone": 0,
    "priority": 100,
    "action": "drop"
  }'

# Response (200): {"result": "Success"}
```

### Field Reference

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `filterType` | string | `"whitelist"`, `"blacklist"` | (required) | Filter list type |
| `cidr` | string | CIDR notation (e.g., `"192.0.2.0/24"`) | (required) | IP range to filter |
| `zone` | int | `0` to N (integer) | `0` | Filtering zone |
| `priority` | int | `0`–`999` (lower = higher priority) | — | Rule priority |
| `action` | string | `"allow"`, `"drop"` | (required) | Action when rule matches |

### Whitelist Example

Allow only trusted networks:

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ipfilter \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "filterType": "whitelist",
    "cidr": "10.0.0.0/8",
    "zone": 0,
    "priority": 100,
    "action": "allow"
  }'

# Response (200): {"result": "Success"}
```

### Blacklist Example

Block a known malicious range:

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ipfilter \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "filterType": "blacklist",
    "cidr": "198.51.100.0/24",
    "zone": 0,
    "priority": 200,
    "action": "drop"
  }'

# Response (200): {"result": "Success"}
```

### API Operations

| Operation | Method | Endpoint | Description |
|-----------|--------|----------|-------------|
| Add filter rule | POST | `/config/ipfilter` | Create a new IP filter rule |
| Remove filter rule | DELETE | `/config/ipfilter` | Remove an existing IP filter rule |
| List all filter rules | GET | `/config/ipfilter/all` | List all rules with packet/byte counters |

## Verify

List all IP filter rules and confirm configuration:

```bash
curl http://loxilb:11111/netlox/v1/config/ipfilter/all \
  -H "Authorization: Bearer <token>"

# Response (200):
# [
#   {
#     "filterType": "blacklist",
#     "cidr": "192.0.2.0/24",
#     "priority": 100,
#     "packets": 0,
#     "bytes": 0
#   }
# ]
```

Each rule includes packet and byte counters that track rule hit rates:

| Counter | Description |
|---------|-------------|
| `packets` | Number of packets matching this rule |
| `bytes` | Total bytes of matching packets |

Use these counters to:

- Verify rules are matching expected traffic
- Identify the most-hit rules for optimization
- Detect attack patterns by monitoring blacklist hit rates

## Troubleshoot

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Rules not matching traffic | Incorrect CIDR format or wrong zone assignment | Verify CIDR notation is correct and zone matches the target interface |
| Counters not incrementing | Rule priority order incorrect or traffic not reaching the filter | Check rule priority values; lower priority = higher precedence |
| Whitelist bypass not working | `filterType` set to `"blacklist"` instead of `"whitelist"` | Verify `filterType` field value matches intended behavior |

## See Also

- [Security Controls API Reference](../reference/api.md#security-controls)
- [SYN Flood Protection](syn-flood.md) — Complementary eBPF-level DDoS mitigation
- [OPA Policy Enforcement](opa-policy-enforcement.md) — Dynamic L4 firewall rules driven by OPA policies
- [Secure Dataplane Overview](secure-dataplane.md) — How eBPF security fits in the layered architecture
- [Security Gateway Overview](overview.md) — Full Security Gateway feature map
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
