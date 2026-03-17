# API Key Management

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## Overview

The AI Gateway provides API key lifecycle management for LLM endpoints. Keys are validated at the eBPF data plane via the CGO bridge — returning `401`, `403`, or `429` responses **before traffic reaches backend vLLM instances**. This means invalid, expired, or rate-limited requests are rejected at line speed without consuming GPU resources.

## Prerequisites

!!! danger "Required: --userservice Flag"
    If the `--userservice` flag is not set when starting loxilb, API key validation is **completely bypassed** — ALL requests are allowed regardless of key. This is a **silent fail-open**, not an error. You will not see any log messages or warnings.

    Source: ai_gateway_dp.go:205-212 — "If UserService is nil, all requests are allowed."

Ensure loxilb is started with `--userservice` to enable API key enforcement.

## API Key Data Model

Each API key is represented by an `ApiKeyEntry` with the following fields:

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| `key_id` | string | Unique identifier for the key (auto-generated or user-provided) | common/common.go:1750 |
| `tenant_id` | string | Tenant or organization identifier — groups keys by customer | common/common.go:1751 |
| `name` | string | Human-readable name for the key (e.g., "prod-llama-key") | common/common.go:1752 |
| `allowed_models` | []string | List of models this key can access. Empty = all models allowed. | common/common.go:1753 |
| `rate_limit_rps` | int | Maximum requests per second for this key | common/common.go:1754 |
| `burst_size` | int | Burst allowance above the RPS limit | common/common.go:1755 |
| `tokens_per_min` | int | Token quota per minute (consumed after SSE stream completion) | common/common.go:1756 |
| `expires_at` | datetime | Key expiration timestamp (ISO 8601) | common/common.go:1757 |
| `enabled` | bool | Active/inactive toggle — disabled keys are immediately rejected | common/common.go:1758 |

## REST API

### Create API Key

```bash
# POST /config/ai/apikey
# Source: common/common.go:1750, api/swagger.yml:5844
curl -X POST http://loxilb:11111/config/ai/apikey \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "acme-corp",
    "name": "prod-llama-key",
    "allowed_models": ["meta-llama/Llama-3-70B"],
    "rate_limit_rps": 100,
    "burst_size": 150,
    "tokens_per_min": 100000,
    "expires_at": "2027-01-01T00:00:00Z"
  }'
```

### List API Keys

```bash
# GET /config/ai/apikey?tenant_id=acme-corp
# Source: api/swagger.yml:5844
curl http://loxilb:11111/config/ai/apikey?tenant_id=acme-corp
```

### Get Single Key

```bash
# GET /config/ai/apikey/{key_id}
# Source: api/swagger.yml:5844
curl http://loxilb:11111/config/ai/apikey/key-abc-123
```

### Delete API Key

```bash
# DELETE /config/ai/apikey/{key_id}
# Source: api/swagger.yml:5844
curl -X DELETE http://loxilb:11111/config/ai/apikey/key-abc-123
```

## Validation Flow

When a request arrives at the AI Gateway, API key validation follows this sequence:

1. **Extract key** — The `X-API-Key` HTTP header is extracted by sockproxy.c
2. **CGO bridge call** — `llb_ai_validate_key()` is called (Source: ai_gateway_dp.go:118-166)
3. **Validation checks:**
    - **Key exists?** → No: return `401 Unauthorized`
    - **Key enabled?** → No: return `401 Unauthorized`
    - **Key expired?** → Yes: return `401 Unauthorized`
    - **Model allowed?** → No (model not in `allowed_models`): return `403 Forbidden`
    - **Rate limit OK?** → No: return `429 Too Many Requests` with `Retry-After` header
4. **Pass** → Request continues to next pipeline stage (rate limiting, security scanning, endpoint selection)

All validation happens at the **data plane** — the C sockproxy calls Go logic via CGO and gets a decision integer back. No external service calls are required for key validation.

## Rate Limiting Integration

API key rate limiting operates in **two stages**:

1. **Per-key bucket** — `rate_limit_rps` and `burst_size` from the `ApiKeyEntry`. Each key has its own token bucket.
2. **Per-tenant bucket** — `TenantRateLimitEntry.rps` applied to all keys belonging to the same `tenant_id`. This prevents a single tenant from monopolizing capacity even if they have many keys.

When either bucket is exhausted, the response is `429 Too Many Requests` with a `Retry-After` header indicating when the bucket refills.

For token-level quotas (consumed after SSE stream completion), see [SSE Quota Management](sse-quota-management.md).

(Source: ai_gateway_dp.go:270)

## See Also

- [SSE Quota Management](sse-quota-management.md) — Token-level quota management
- [AI Gateway Overview](overview.md) — Full traffic flow and architecture
- [Configuration Reference](configuration-reference.md) — All AI Gateway config fields
