# SSE Quota Management

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is SSE Streaming?

Server-Sent Events (SSE) is an HTTP streaming protocol where the server pushes events to the client over a single long-lived connection. LLMs use SSE to stream tokens as they are generated — each `data: <token>` event arrives in real time, giving users the experience of watching the AI "think."

Think of SSE as HTTP chunked transfer encoding optimized for real-time updates. The connection stays open for the entire generation process, which can take seconds to minutes depending on the response length and GPU capacity.

## The SSE Challenge for Load Balancers

Standard load balancers have **idle timeouts** that kill connections without activity. An LLM inference that takes 30 seconds between token emissions would be terminated by a typical 10-second idle timeout. This is catastrophic for users — their response is cut off mid-sentence.

loxilb solves this with `sse_mode: true`, which **suppresses idle timeout during active SSE streams**. The connection stays alive for the entire generation process, up to the configured maximum duration.

## Configuration

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/services \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "serviceArguments": {
      "externalIP": "192.168.1.100",
      "port": 443,
      "protocol": "tcp",
      "mode": 4,
      "backend_protocol": "http1",
      "sse_mode": true,
      "max_stream_duration_sec": 3600
    },
    "endpoints": [
      {"endpointIP": "10.0.1.1", "targetPort": 8080, "weight": 1}
    ]
  }'

# Response (200):
# {"result": "Success"}
```

**`max_stream_duration_sec`:** Maximum allowed stream duration in seconds. Set `0` for the hard cap of 86400 seconds (24 hours, from `PROXY_SSE_HARD_CAP_SEC`). For production, set an explicit value based on your longest expected generation time.

## Token Quota Management

!!! info "Quota Timing: After Stream Completion"
    Token quotas are consumed **AFTER** the SSE stream completes, not mid-stream. A stream that exceeds the remaining quota will complete successfully — the **NEXT** request is blocked with `429 Too Many Requests`.

    This means a user will never have their response cut off due to quota exhaustion. The quota check prevents the next request, not the current one.


### How Token Counting Works

loxilb tracks SSE stream lifecycle events via CGO bridge functions:

| Event | Function | Trigger |
|-------|----------|---------|
| Stream start | `llb_ai_stream_start()` | Response contains `Content-Type: text/event-stream` |
| Stream end | `llb_ai_stream_end()` | SSE event `data: [DONE]` received |
| Quota consume | `llb_ai_token_quota_consume()` | After stream end, extract usage from final chunk |


### Missing Usage Chunk

Some vLLM configurations do not include token counts in the final SSE chunk (`promptTokens=0` AND `completionTokens=0`). In this case:

- **Quota is NOT charged** — best-effort mode
- **Counter incremented** — `loxilb_ai_tokens_missing_total` Prometheus metric tracks how often this occurs

This means token quotas are only as accurate as the backend's usage reporting. If your vLLM instances consistently omit usage chunks, token quotas will not be enforced. Monitor the `loxilb_ai_tokens_missing_total` metric to detect this condition.

## Tenant Rate Limit Configuration

Token quotas are configured per-tenant via the REST API:

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ai/tenant/ratelimit \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "acme-corp",
    "rps": 500,
    "tokens_per_min": 1000000
  }'

# Response (204): No content — upsert applied
```

### Get Tenant Rate Limit

```bash
curl http://loxilb:11111/netlox/v1/config/ai/tenant/ratelimit/acme-corp \
  -H "Authorization: Bearer <token>"

# Response (200):
# {
#   "tenant_id": "acme-corp",
#   "rps": 500,
#   "tokens_per_min": 1000000,
#   "updated_at": "2026-03-18T10:30:00Z"
# }
```

### Tenant Rate Limit Fields

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `tenant_id` | string | any string | - | Tenant identifier (matches API key `tenant_id`) |
| `rps` | int | > 0 | `0` (unlimited) | Requests per second limit for this tenant (all keys combined) |
| `tokens_per_min` | int | > 0 | `0` (unlimited) | Token quota per minute for this tenant |

### SSE Configuration Fields

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `sse_mode` | bool | `true`, `false` | `false` | Suppress idle timeout during SSE streaming |
| `max_stream_duration_sec` | int | >= 0 | `0` (24h cap) | Maximum stream duration in seconds. `0` = 24-hour hard cap |

## Verify

Confirm tenant rate limits are configured:

```bash
curl http://loxilb:11111/netlox/v1/config/ai/tenant/ratelimit/acme-corp \
  -H "Authorization: Bearer <token>"

# Expected response:
# {
#   "tenant_id": "acme-corp",
#   "rps": 500,
#   "tokens_per_min": 1000000
# }
```

Also verify SSE mode is enabled on your service rule by checking the service listing:

```bash
curl http://loxilb:11111/netlox/v1/config/services \
  -H "Authorization: Bearer <token>"
```

Confirm `sse_mode: true` is set in the response for your AI Gateway service.

## Troubleshooting

### Streams Killed Mid-Response

**Symptoms:** LLM responses are truncated — the connection closes before `data: [DONE]` is received.

**Check:**

1. **`sse_mode` enabled?** — Without `sse_mode: true`, idle timeouts kill long-running connections.
2. **`max_stream_duration_sec`** — If set too low, streams exceeding this duration are terminated. Set `0` for 24-hour hard cap, or set an explicit value matching your longest expected generation.
3. **Network timeouts** — Check for intermediate load balancers or proxies (AWS NLB, nginx) with their own idle timeouts.

### Quota Not Enforced

**Symptoms:** Tenants exceed their `tokens_per_min` limit without receiving `429` responses.

**Check:**

1. **`--userservice` flag** — API key and quota enforcement requires the `--userservice` flag at startup. See [API Key Management](api-key-management.md).
2. **Tenant rate limit configured?** — Verify with `GET /config/ai/tenant/ratelimit?tenant_id=<id>`.
3. **Missing usage chunks** — Check `loxilb_ai_tokens_missing_total` metric. If vLLM omits usage data, quotas cannot be enforced.

### Missing Token Counts

**Symptoms:** `loxilb_ai_tokens_missing_total` metric is increasing.

**Check:**

1. **vLLM configuration** — Ensure vLLM is configured to include usage statistics in SSE stream responses. Check the `--return-usage` or equivalent flag.
2. **Response format** — The final SSE chunk should include `usage: { "prompt_tokens": N, "completion_tokens": M }`. If this field is missing or zero, loxilb cannot count tokens.

## See Also

- [API Key Management](api-key-management.md) — Per-key rate limiting and the `--userservice` prerequisite
- [AI Gateway Overview](overview.md) — Full traffic flow showing where SSE quota fits in the pipeline
- [Configuration Reference](configuration-reference.md) — All AI Gateway config fields
- [Tenant Rate Limits API Reference](../reference/api.md#ai-gateway-tenant-rate-limits)
