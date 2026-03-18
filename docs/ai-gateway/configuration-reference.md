# AI Gateway Configuration Reference

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

This page consolidates all AI Gateway configuration fields in one place. For conceptual explanations and usage guidance, see the linked feature pages.

## Service Arguments

### Core

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `mode` | int | `4` | - | **Must be `4`** (LBModeFullProxy) for all AI Gateway features | [Overview](overview.md) |
| `backend_protocol` | string | `http1` | - | **Must be `"http1"`** for AI Gateway features | [Overview](overview.md) |
| `sel` | int | `8`, `9`, `10` | - | LB selection algorithm. See [LB Selection Modes](#lb-selection-modes) | [LLM Routing](llm-routing.md) |
| `llm_type` | string | `chat-interactive`, `rag-longcontext` | - | GPU routing catalog profile | [Model Load Balancing](model-load-balancing.md) |
| `model_name` | string | any model identifier | - | Model name for per-model endpoint pools. Omit for wildcard pool | [Model Load Balancing](model-load-balancing.md) |

### KV Cache Routing

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `kvExactMode` | int | `0`, `1` | `0` | KV-exact routing mode. `0`=off, `1`=zmq subscriber mode | [KV Caching](kv-caching.md) |
| `kvBlockSize` | int | > 0 | `16` | Number of tokens per block for hashing | [KV Caching](kv-caching.md) |
| `kvHashAlgo` | string | `sha256_cbor`, `xxhash_cbor` | `"sha256_cbor"` | Hash algorithm for token block hashing | [KV Caching](kv-caching.md) |
| `kvZmqPort` | int | 1–65535 | `5557` | ZMQ PUB socket port on each vLLM instance | [KV Caching](kv-caching.md) |
| `kvWarmupSec` | int | >= 0 | `30` | Seconds to wait before activating Tier 1.5 routing | [KV Caching](kv-caching.md) |

### PD Disaggregation

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `pd_disagg_mode` | bool | `true`, `false` | `false` | Enable prefill/decode disaggregation | [PD Disaggregation](pd-disaggregation.md) |
| `pd_cache_aware_mode` | bool | `true`, `false` | `false` | Enable session stickiness + trie matching + min-load for decode endpoints | [PD Disaggregation](pd-disaggregation.md) |
| `pd_session_ttl_sec` | int | > 0 | `300` | Session stickiness TTL for decode endpoints (seconds) | [PD Disaggregation](pd-disaggregation.md) |
| `pd_cache_threshold` | int | 0–100 | `20` | Minimum cache match percentage to stick to a decode endpoint | [PD Disaggregation](pd-disaggregation.md) |
| `pd_balance_abs_threshold` | int | >= 0 | `3` | Maximum load imbalance tolerance before rebalancing | [PD Disaggregation](pd-disaggregation.md) |

### SSE Streaming

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `sse_mode` | bool | `true`, `false` | `false` | Suppress idle timeout during SSE streaming | [SSE Quota Management](sse-quota-management.md) |
| `max_stream_duration_sec` | int | >= 0 | `0` | Maximum stream duration in seconds. `0` = 24h hard cap | [SSE Quota Management](sse-quota-management.md) |

## Endpoint Fields

| Field | Type | Valid Values | Default | Description | Feature Page |
|-------|------|-------------|---------|-------------|-------------|
| `endpointIP` | string | IP address | - | Backend vLLM instance IP address | - |
| `targetPort` | int | 1–65535 | - | Backend vLLM serving port | - |
| `weight` | int | >= 1 | `1` | Endpoint weight for weighted selection modes | - |
| `ep_role` | int | `0`, `1`, `2` | `0` | Endpoint role: `0`=normal, `1`=prefill, `2`=decode | [PD Disaggregation](pd-disaggregation.md) |
| `nixl_port` | int | 1–65535 | - | NIXL sideband port for KV cache transfer (prefill endpoints only) | [PD Disaggregation](pd-disaggregation.md) |

## LB Selection Modes

Selection modes optimized for LLM workloads:

| `sel` Value | Name | Description | Best For |
|-------------|------|-------------|----------|
| `8` | LbSelCHWBL | Consistent hash with bounded loads | Conversational workloads — preserves KV cache locality |
| `9` | LbSelGPUAware | GPU queue-depth scoring from vLLM metrics | Batch/independent queries — optimizes for throughput |
| `10` | LbSelWRRHash | Weighted round-robin with hash | Mixed workloads or transition from standard LB |

See [LLM Routing](llm-routing.md) for detailed guidance on choosing a selection mode.

## REST API Endpoints

| Method | Path | Description | Feature Page |
|--------|------|-------------|-------------|
| `POST` | `/config/ai/apikey` | Create API key | [API Key Management](api-key-management.md) |
| `GET` | `/config/ai/apikey` | List API keys (filter by `?tenant_id=`) | [API Key Management](api-key-management.md) |
| `GET` | `/config/ai/apikey/{key_id}` | Get single API key | [API Key Management](api-key-management.md) |
| `DELETE` | `/config/ai/apikey/{key_id}` | Delete API key | [API Key Management](api-key-management.md) |
| `POST` | `/config/ai/tenant/ratelimit` | Set tenant rate limit (RPS + tokens/min) | [SSE Quota Management](sse-quota-management.md) |

## Prerequisites Checklist

Before configuring AI Gateway features, verify:

- [ ] loxilb-enterprise binary installed (not community edition)
- [ ] `mode: 4` (LBModeFullProxy) set on LB service
- [ ] `backend_protocol: "http1"` set on LB service
- [ ] `--userservice` flag set at loxilb startup (for API key enforcement)
- [ ] vLLM started with `--enable-metrics` (for GPU-aware selection)
- [ ] Tokenizer files staged at `/etc/loxilb/tokenizers/` (for KV-exact routing)
- [ ] ZMQ port 5557 open between loxilb and vLLM instances (for KV-exact routing)

## See Also

- [AI Gateway Overview](overview.md) — Conceptual introduction and traffic flow
- [LLM Routing](llm-routing.md) — Three-tier routing architecture
- [KV Caching](kv-caching.md) — KV-exact routing configuration
- [vLLM Integration](vllm-integration.md) — GPU metrics scraping
- [Model Load Balancing](model-load-balancing.md) — Per-model endpoint pools
- [PD Disaggregation](pd-disaggregation.md) — Prefill/decode separation
- [API Key Management](api-key-management.md) — API key lifecycle
- [SSE Quota Management](sse-quota-management.md) — Token quota management
- [API Key Management API Reference](../reference/api.md#ai-gateway-api-key-management)
- [Tenant Rate Limits API Reference](../reference/api.md#ai-gateway-tenant-rate-limits)
- [GPU and LLM Catalog API Reference](../reference/api.md#ai-gateway-gpu-and-llm-catalog)
