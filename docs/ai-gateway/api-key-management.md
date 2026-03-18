# API Key Management

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## Overview

The AI Gateway provides API key lifecycle management for LLM endpoints. Keys are validated at the eBPF data plane via the CGO bridge — returning `401`, `403`, or `429` responses **before traffic reaches backend vLLM instances**. This means invalid, expired, or rate-limited requests are rejected at line speed without consuming GPU resources.

## Prerequisites

!!! danger "Required: --userservice Flag"
    If the `--userservice` flag is not set when starting loxilb, API key validation is **completely bypassed** — ALL requests are allowed regardless of key. This is a **silent fail-open**, not an error. You will not see any log messages or warnings.

Ensure loxilb is started with `--userservice` to enable API key enforcement.

## API Key Data Model

Each API key is represented by an `ApiKeyEntry` with the following fields:

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `key_id` | string | auto-generated | - | Unique identifier for the key |
| `tenant_id` | string | any string | - | Tenant or organization identifier — groups keys by customer |
| `name` | string | any string | `""` | Human-readable name for the key (e.g., "prod-llama-key") |
| `allowed_models` | []string | model names | `[]` (all) | List of models this key can access. Empty = all models allowed |
| `rate_limit_rps` | int | > 0 | `0` (unlimited) | Maximum requests per second for this key |
| `burst_size` | int | > 0 | `0` | Burst allowance above the RPS limit |
| `tokens_per_min` | int | > 0 | `0` (unlimited) | Token quota per minute (consumed after SSE stream completion) |
| `expires_at` | datetime | ISO 8601 | (none) | Key expiration timestamp |
| `enabled` | bool | `true`, `false` | `true` | Active/inactive toggle — disabled keys are immediately rejected |

## REST API Config

### Create API Key

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ai/apikey \
  -H "Authorization: Bearer <token>" \
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

# Response (201):
# {
#   "key_id": "ak_abc123def456",
#   "raw_key": "lxk_live_a1b2c3d4e5f6..."
# }
```

!!! warning "Save the Raw Key"
    The `raw_key` is shown **only once** in the create response. Store it securely — it cannot be retrieved later.

### List API Keys

```bash
curl http://loxilb:11111/netlox/v1/config/ai/apikey?tenant_id=acme-corp \
  -H "Authorization: Bearer <token>"

# Response (200):
# [
#   {
#     "key_id": "ak_abc123def456",
#     "tenant_id": "acme-corp",
#     "name": "prod-llama-key",
#     "allowed_models": ["meta-llama/Llama-3-70B"],
#     "rate_limit_rps": 100,
#     "burst_size": 150,
#     "tokens_per_min": 100000,
#     "enabled": true,
#     "expires_at": "2027-01-01T00:00:00Z"
#   }
# ]
```

### Get Single Key

```bash
curl http://loxilb:11111/netlox/v1/config/ai/apikey/ak_abc123def456 \
  -H "Authorization: Bearer <token>"

# Response (200):
# {
#   "key_id": "ak_abc123def456",
#   "tenant_id": "acme-corp",
#   "name": "prod-llama-key",
#   "allowed_models": ["meta-llama/Llama-3-70B"],
#   "rate_limit_rps": 100,
#   "burst_size": 150,
#   "tokens_per_min": 100000,
#   "enabled": true,
#   "expires_at": "2027-01-01T00:00:00Z"
# }
```

### Delete API Key

```bash
curl -X DELETE http://loxilb:11111/netlox/v1/config/ai/apikey/ak_abc123def456 \
  -H "Authorization: Bearer <token>"

# Response (200):
# {"result": "Success"}
```

## Validation Flow

When a request arrives at the AI Gateway, API key validation follows this sequence:

1. **Extract key** — The `X-API-Key` HTTP header is extracted by sockproxy.c
2. **CGO bridge call** — `llb_ai_validate_key()` is called
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

## Verify

Confirm an API key was created and is active:

```bash
curl http://loxilb:11111/netlox/v1/config/ai/apikey/ak_abc123def456 \
  -H "Authorization: Bearer <token>"

# Expected response:
# {
#   "key_id": "ak_abc123def456",
#   "enabled": true,
#   "tenant_id": "acme-corp"
# }
```

## Troubleshooting

**API key rejected at gateway (401 Unauthorized)**

- Verify the key exists: `GET /config/ai/apikey/<key_id>`
- Check `enabled` is `true` — disabled keys are immediately rejected
- Check `expires_at` has not passed

**Rate limit exceeded (429 Too Many Requests)**

- Check `rate_limit_rps` and `burst_size` on the key: `GET /config/ai/apikey/<key_id>`
- Check tenant-level limits: `GET /config/ai/tenant/ratelimit/<tenant_id>`
- The `Retry-After` response header indicates when the bucket refills

**Model not allowed (403 Forbidden)**

- Check `allowed_models` on the key — ensure the requested model is in the list
- Empty `allowed_models` means all models are allowed

## See Also

- [SSE Quota Management](sse-quota-management.md) — Token-level quota management
- [AI Gateway Overview](overview.md) — Full traffic flow and architecture
- [Configuration Reference](configuration-reference.md) — All AI Gateway config fields
- [API Key Management API Reference](../reference/api.md#ai-gateway-api-key-management)
