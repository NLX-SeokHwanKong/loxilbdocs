# Rate Limiting

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is Rate Limiting?

Rate limiting protects backend services from overload by enforcing request-per-second (RPS) and burst limits at the gateway layer. For AI Gateway deployments, it also enforces **token-per-minute quotas** to control LLM inference costs — a critical feature when GPU resources are shared across multiple tenants.

loxilb uses a **token-bucket algorithm** (golang.org/x/time/rate) that provides smooth rate limiting with configurable burst capacity. Rate limits are enforced at three dimensions: per API key, per tenant, and per-key token quota.

## Three Rate Limiting Dimensions

### Per-Key Rate Limiting (RPS + Burst)

Each API key has independent `rate_limit_rps` and `burst_size` limits. The token-bucket algorithm works as follows:

- The bucket refills at `rps` tokens per second
- Each request consumes one token
- `burst_size` is the maximum bucket capacity — allowing short bursts above the sustained rate
- When the bucket is empty, requests are rejected with a `retryAfter` duration

```go
// Source: pkg/ratelimit/ratelimit.go:105-113
// Per-key check: rps=100, burst=200
allowed, retryAfter := store.CheckKey(keyID, 100, 200)
```

**Example:** With `rps=100` and `burst=200`, a client can send 200 requests instantly (draining the burst), then sustain 100 requests per second. If they exceed this, requests are rejected until the bucket refills.

### Per-Tenant Rate Limiting (RPS)

Tenant-level rate limiting aggregates all API keys belonging to a tenant. This prevents any single tenant from monopolizing gateway capacity, even if they have many API keys.

```go
// Source: pkg/ratelimit/ratelimit.go
// Per-tenant check: rps=500 (shared across all tenant's keys)
allowed, retryAfter := store.CheckTenant(tenantID, 500)
```

### Per-Key Token Quota (AI-Specific)

For AI Gateway deployments, token quotas control LLM token consumption per minute per API key. This is critical for cost management — LLM inference cost scales linearly with token count.

```go
// Source: pkg/ratelimit/ratelimit.go
// Per-key token quota: 10000 tokens/minute
allowed, retryAfter := store.AllowTokens(tenantID, tokenCount, 10000)
```

The `tokens_per_min` field controls how many LLM tokens a key can consume per minute. When exceeded, requests are rejected until the next minute window.

## Configuration

Rate limits are configured as part of API key creation:

```json
// Source: pkg/user/api_key.go:37-55 (DB schema)
{
  "rate_limit_rps": 100,
  "burst_size": 200,
  "tokens_per_min": 10000
}
```

| Field | Type | Description |
|-------|------|-------------|
| `rate_limit_rps` | int | Sustained requests per second per key |
| `burst_size` | int | Maximum burst capacity (bucket size) |
| `tokens_per_min` | int | LLM token quota per minute per key |

## Rate Limit Response

When a request is rate-limited, the gateway returns a rejection with a `retryAfter` duration indicating when the client can retry:

```go
// Source: pkg/ratelimit/ratelimit.go
// CheckKey returns (allowed bool, retryAfter time.Duration)
allowed, retryAfter := store.CheckKey(keyID, rps, burst)
if !allowed {
    // Reject with retryAfter hint
}
```

## Cleanup and Memory Management

The rate limiter store runs a background cleanup goroutine that removes entries with more than 10 minutes of inactivity. This prevents memory growth from expired or abandoned API keys.

Source: `pkg/ratelimit/ratelimit.go` — cleanup goroutine

## See Also

- [Security Gateway Overview](overview.md) — Security Gateway architecture and feature map
- [SYN Flood Protection](syn-flood.md) — Network-level rate limiting for DDoS mitigation
- [AI Gateway Overview](../ai-gateway/overview.md) — API key management and AI traffic flow
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
