# IP Filtering

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is IP Filtering?

IP filtering provides IP-based access control at the eBPF dataplane level. You can whitelist trusted CIDR ranges or blacklist known-bad IP ranges, and rules are enforced in the **kernel fast path** before any application processing occurs.

This is the first line of defense — packets matching blacklist rules are dropped at the TC hook with minimal CPU overhead. For network administrators, IP filtering provides the equivalent of edge firewall ACLs, but implemented in eBPF for high-throughput environments.

## Filter Configuration

### Adding a Filter Rule

```json
// Source: common/common.go:465-477 (IPFilterMod)
POST /config/ipfilter
{
  "filterType": "blacklist",
  "cidr": "192.0.2.0/24",
  "zone": 0,
  "priority": 100,
  "action": "drop"
}
```

### Field Reference

| Field | Type | Description | Values |
|-------|------|-------------|--------|
| `filterType` | string | Filter list type | `"whitelist"` or `"blacklist"` |
| `cidr` | string | IP range in CIDR notation | e.g., `"192.0.2.0/24"`, `"10.0.0.1/32"` |
| `zone` | int | Filtering zone | Default: `0` |
| `priority` | int | Rule priority (higher = processed first) | e.g., `100` |
| `action` | string | Action when rule matches | `"allow"` or `"drop"` |

### Whitelist Example

Allow only trusted networks:

```json
POST /config/ipfilter
{
  "filterType": "whitelist",
  "cidr": "10.0.0.0/8",
  "zone": 0,
  "priority": 100,
  "action": "allow"
}
```

### Blacklist Example

Block a known malicious range:

```json
POST /config/ipfilter
{
  "filterType": "blacklist",
  "cidr": "198.51.100.0/24",
  "zone": 0,
  "priority": 200,
  "action": "drop"
}
```

## API Operations

| Operation | Method | Endpoint | Description |
|-----------|--------|----------|-------------|
| Add filter rule | POST | `/config/ipfilter` | Create a new IP filter rule |
| Remove filter rule | DELETE | `/config/ipfilter` | Remove an existing IP filter rule |
| List all filter rules | GET | `/config/ipfilter/all` | List all rules with packet/byte counters |

Source: swagger.yml:3171 and 3194, `pkg/loxinet/apiclient.go:599-695`

## Monitoring

Each `IPFilterEntry` includes packet and byte counters that track rule hit rates:

```bash
# List all IP filter rules with counters
curl http://localhost:11111/config/ipfilter/all
```

The response includes for each rule:

| Counter | Description |
|---------|-------------|
| `packets` | Number of packets matching this rule |
| `bytes` | Total bytes of matching packets |

Use these counters to:

- Verify rules are matching expected traffic
- Identify the most-hit rules for optimization
- Detect attack patterns by monitoring blacklist hit rates

## See Also

- [SYN Flood Protection](syn-flood.md) — Complementary eBPF-level DDoS mitigation
- [OPA Policy Enforcement](opa-policy-enforcement.md) — Dynamic L4 firewall rules driven by OPA policies
- [Secure Dataplane Overview](secure-dataplane.md) — How eBPF security fits in the layered architecture
- [Security Gateway Overview](overview.md) — Full Security Gateway feature map
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
