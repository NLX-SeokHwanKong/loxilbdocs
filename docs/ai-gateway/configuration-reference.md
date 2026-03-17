# AI Gateway Configuration Reference

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

This page consolidates all AI Gateway configuration fields in one place. For conceptual explanations and usage guidance, see the linked feature pages.

## Service Arguments

### Core

| Field | Type | Default | Description | Feature Page | Source |
|-------|------|---------|-------------|-------------|--------|
| `mode` | int | - | **Must be `4`** (LBModeFullProxy) for all AI Gateway features | [Overview](overview.md) | common/common.go:885 |
| `backend_protocol` | string | - | **Must be `"http1"`** for AI Gateway features | [Overview](overview.md) | common/common.go:885 |
| `sel` | int | - | LB selection algorithm. See [LB Selection Modes](#lb-selection-modes) | [LLM Routing](llm-routing.md) | common/common.go:674-699 |
| `llm_type` | string | - | GPU routing catalog profile (e.g., `"chat-interactive"`, `"rag-longcontext"`) | [Model Load Balancing](model-load-balancing.md) | common/common.go:858 |
| `model_name` | string | - | Model name for per-model endpoint pools. Omit for wildcard pool. | [Model Load Balancing](model-load-balancing.md) | common/common.go:858 |

### KV Cache Routing

| Field | Type | Default | Description | Feature Page | Source |
|-------|------|---------|-------------|-------------|--------|
| `kvExactMode` | int | `0` | KV-exact routing mode. `0`=off, `1`=zmq subscriber mode | [KV Caching](kv-caching.md) | common/common.go:899 |
| `kvBlockSize` | int | `16` | Number of tokens per block for hashing | [KV Caching](kv-caching.md) | common/common.go:901 |
| `kvHashAlgo` | string | `"sha256_cbor"` | Hash algorithm. Options: `sha256_cbor`, `xxhash_cbor` | [KV Caching](kv-caching.md) | common/common.go:903 |
| `kvZmqPort` | int | `5557` | ZMQ PUB socket port on each vLLM instance | [KV Caching](kv-caching.md) | common/common.go:904 |
| `kvWarmupSec` | int | `30` | Seconds to wait before activating Tier 1.5 routing | [KV Caching](kv-caching.md) | common/common.go:906 |

### PD Disaggregation

| Field | Type | Default | Description | Feature Page | Source |
|-------|------|---------|-------------|-------------|--------|
| `pd_disagg_mode` | bool | `false` | Enable prefill/decode disaggregation | [PD Disaggregation](pd-disaggregation.md) | common/common.go:886 |
| `pd_cache_aware_mode` | bool | `false` | Enable session stickiness + trie matching + min-load for decode endpoints | [PD Disaggregation](pd-disaggregation.md) | common/common.go:889 |
| `pd_session_ttl_sec` | int | `300` | Session stickiness TTL for decode endpoints (seconds) | [PD Disaggregation](pd-disaggregation.md) | common/common.go:891 |
| `pd_cache_threshold` | int | `20` | Minimum cache match percentage to stick to a decode endpoint | [PD Disaggregation](pd-disaggregation.md) | common/common.go:893 |
| `pd_balance_abs_threshold` | int | `3` | Maximum load imbalance tolerance before rebalancing | [PD Disaggregation](pd-disaggregation.md) | common/common.go:895 |

### SSE Streaming

| Field | Type | Default | Description | Feature Page | Source |
|-------|------|---------|-------------|-------------|--------|
| `sse_mode` | bool | `false` | Suppress idle timeout during SSE streaming | [SSE Quota Management](sse-quota-management.md) | common/common.go:878 |
| `max_stream_duration_sec` | int | `0` | Maximum stream duration in seconds. `0` = 24h hard cap (`PROXY_SSE_HARD_CAP_SEC`) | [SSE Quota Management](sse-quota-management.md) | common/common.go:882 |

## Endpoint Fields

| Field | Type | Default | Description | Feature Page | Source |
|-------|------|---------|-------------|-------------|--------|
| `endpointIP` | string | - | Backend vLLM instance IP address | - | common/common.go:925 |
| `targetPort` | int | - | Backend vLLM serving port | - | common/common.go:925 |
| `weight` | int | `1` | Endpoint weight for weighted selection modes | - | common/common.go:925 |
| `ep_role` | int | `0` | Endpoint role: `0`=normal, `1`=prefill, `2`=decode | [PD Disaggregation](pd-disaggregation.md) | common/common.go:941 |
| `nixl_port` | int | - | NIXL sideband port for KV cache transfer (prefill endpoints only) | [PD Disaggregation](pd-disaggregation.md) | common/common.go:943 |

## LB Selection Modes

Selection modes optimized for LLM workloads:

| `sel` Value | Name | Description | Best For | Source |
|-------------|------|-------------|----------|--------|
| `8` | LbSelCHWBL | Consistent hash with bounded loads | Conversational workloads — preserves KV cache locality | common/common.go:694 |
| `9` | LbSelGPUAware | GPU queue-depth scoring from vLLM metrics | Batch/independent queries — optimizes for throughput | common/common.go:696 |
| `10` | LbSelWRRHash | Weighted round-robin with hash | Mixed workloads or transition from standard LB | common/common.go:698 |

See [LLM Routing](llm-routing.md) for detailed guidance on choosing a selection mode.

## REST API Endpoints

| Method | Path | Description | Feature Page | Source |
|--------|------|-------------|-------------|--------|
| `POST` | `/config/ai/apikey` | Create API key | [API Key Management](api-key-management.md) | swagger.yml:5844 |
| `GET` | `/config/ai/apikey` | List API keys (filter by `?tenant_id=`) | [API Key Management](api-key-management.md) | swagger.yml:5844 |
| `GET` | `/config/ai/apikey/{key_id}` | Get single API key | [API Key Management](api-key-management.md) | swagger.yml:5844 |
| `DELETE` | `/config/ai/apikey/{key_id}` | Delete API key | [API Key Management](api-key-management.md) | swagger.yml:5844 |
| `POST` | `/config/ai/tenant/ratelimit` | Set tenant rate limit (RPS + tokens/min) | [SSE Quota Management](sse-quota-management.md) | swagger.yml:5958 |

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
