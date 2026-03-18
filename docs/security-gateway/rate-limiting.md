# Rate Limiting

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is Rate Limiting?

Rate limiting protects backend services from overload by enforcing request-per-second (RPS) and burst limits at the gateway layer. For AI Gateway deployments, it also enforces **token-per-minute quotas** to control LLM inference costs — a critical feature when GPU resources are shared across multiple tenants.

loxilb uses a **token-bucket algorithm** that provides smooth rate limiting with configurable burst capacity. Rate limits are enforced at three dimensions: per API key, per tenant, and per-key token quota.

## Three Rate Limiting Dimensions

### Per-Key Rate Limiting (RPS + Burst)

Each API key has independent `rate_limit_rps` and `burst_size` limits. The token-bucket algorithm works as follows:

- The bucket refills at `rps` tokens per second
- Each request consumes one token
- `burst_size` is the maximum bucket capacity — allowing short bursts above the sustained rate
- When the bucket is empty, requests are rejected with a `retryAfter` duration

**Example:** With `rps=100` and `burst=200`, a client can send 200 requests instantly (draining the burst), then sustain 100 requests per second. If they exceed this, requests are rejected until the bucket refills.

### Per-Tenant Rate Limiting (RPS)

Tenant-level rate limiting aggregates all API keys belonging to a tenant. This prevents any single tenant from monopolizing gateway capacity, even if they have many API keys.

### Per-Key Token Quota (AI-Specific)

For AI Gateway deployments, token quotas control LLM token consumption per minute per API key. This is critical for cost management — LLM inference cost scales linearly with token count.

The `tokens_per_min` field controls how many LLM tokens a key can consume per minute. When exceeded, requests are rejected until the next minute window.

## REST API Configuration

Rate limits are configured as part of API key creation via `POST /config/ai/apikey`:

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ai/apikey \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "org-acme",
    "allowed_models": ["gpt-4", "gpt-3.5-turbo"],
    "rate_limit_rps": 100,
    "burst_size": 150,
    "daily_token_quota": 1000000,
    "expires_at": "2026-12-31T23:59:59Z"
  }'

# Response (201):
# {
#   "key_id": "key_abc123",
#   "raw_key": "lxk_...",
#   "tenant_id": "org-acme",
#   "rate_limit_rps": 100,
#   "burst_size": 150
# }
```

### Rate Limiting Field Reference

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `rate_limit_rps` | int | `> 0` (requests/sec) | — | Sustained requests per second per key |
| `burst_size` | int | `> 0` (requests) | — | Maximum burst capacity (bucket size) |
| `daily_token_quota` | int | `> 0` (tokens) | — | LLM token quota per day per key |
| `concurrent_limit` | int | `> 0` (connections) | — | Maximum concurrent requests per key |

### Rate Limit Response

When a request is rate-limited, the gateway returns a rejection with a `retryAfter` duration indicating when the client can retry.

## Cleanup and Memory Management

The rate limiter store runs a background cleanup goroutine that removes entries with more than 10 minutes of inactivity. This prevents memory growth from expired or abandoned API keys.

## Verify

Confirm rate limit configuration is applied to an API key:

```bash
curl http://loxilb:11111/netlox/v1/config/ai/apikey/{key_id} \
  -H "Authorization: Bearer <token>"

# Response (200):
# {
#   "key_id": "key_abc123",
#   "tenant_id": "org-acme",
#   "rate_limit_rps": 100,
#   "burst_size": 150,
#   "daily_token_quota": 1000000,
#   "status": "active"
# }
```

Check that `rate_limit_rps`, `burst_size`, and `daily_token_quota` match your intended configuration.

## Troubleshoot

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Rate limits not enforced | `rate_limit_rps` or `burst_size` not set on the API key | Verify key configuration via `GET /config/ai/apikey/{key_id}` |
| Token quota exceeded unexpectedly | `daily_token_quota` too low for workload | Increase `daily_token_quota` value or review token consumption patterns |
| Burst rejected despite low average rate | `burst_size` too small for traffic pattern | Increase `burst_size` to accommodate traffic spikes |

## See Also

- [AI Gateway API Key Management](../reference/api.md#ai-gateway-api-key-management)
- [Security Controls API Reference](../reference/api.md#security-controls)
- [Security Gateway Overview](overview.md) — Security Gateway architecture and feature map
- [SYN Flood Protection](syn-flood.md) — Network-level rate limiting for DDoS mitigation
- [AI Gateway Overview](../ai-gateway/overview.md) — API key management and AI traffic flow
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
