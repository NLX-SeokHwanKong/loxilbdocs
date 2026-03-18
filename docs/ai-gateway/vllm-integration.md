# vLLM Integration

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is vLLM?

vLLM is an open-source LLM inference engine that runs on GPUs. Think of it as the **application server** behind your load balancer — it receives prompts, runs them through the language model on the GPU, and returns generated text. loxilb's AI Gateway integrates with vLLM's Prometheus metrics endpoint to make intelligent routing decisions based on real-time GPU utilization.

## How loxilb Scrapes vLLM Metrics

The `VllmScraper` component polls each backend vLLM instance's `/metrics` HTTP endpoint at a regular interval (default: every 10 seconds). It extracts two key metrics that inform endpoint selection:

| Metric | Type | What It Measures | Used For |
|--------|------|-----------------|----------|
| `vllm:num_requests_waiting` | Gauge | Number of requests queued, waiting for GPU time | Tier 2 queue-depth scoring |
| `vllm:gpu_cache_usage_perc` | Gauge | GPU KV cache fill percentage (0.0 to 1.0) | Cache pressure detection |

After scraping, the `VllmScraper` updates the C-side queue depth via `llb_ai_update_ep_queue_depth()` CGO call. This makes real-time GPU metrics available to the data-plane endpoint selection algorithm without additional latency on the request path.

**Scraper details:**

- Scrape interval: 10 seconds (configurable via `NewVllmScraper` interval parameter)
- Timeout per scrape request: 5 seconds

## GPU-Aware Load Balancing

With vLLM metrics available, you can enable **GPU-aware endpoint selection** using `sel: 9` (LbSelGPUAware). This mode uses the scraped metrics to find the least-loaded, most-available GPU for each request.

The selection algorithm combines queue depth and cache usage:

- **Low queue depth** = GPU has capacity for new requests
- **Low cache usage** = GPU has room for new KV cache entries
- **Optimal endpoint** = lowest combined load score

### When to Use GPU-Aware vs CHWBL

| Selection Mode | `sel` Value | Best For | Trade-off |
|---------------|-------------|----------|-----------|
| **LbSelCHWBL** (Consistent Hash) | `8` | Conversational workloads | Preserves KV cache locality via consistent hash. Same prompt → same GPU. Best when cache reuse matters. |
| **LbSelGPUAware** | `9` | Batch/independent queries | Optimizes for throughput by routing to least-loaded GPU. Better when each request is independent (no conversation continuity). |

**Guideline:** If your users have multi-turn conversations (chat applications), use `sel: 8` with KV-exact routing. If your workload is primarily independent single-shot queries (batch inference, RAG pipelines), use `sel: 9` for throughput optimization.

## REST API Config

The vLLM scraper auto-activates when AI Gateway endpoints are configured — there is no separate scraper configuration in the LB rule. Configure GPU-aware load balancing via `POST /config/services`:

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
      "sel": 9,
      "backend_protocol": "http1"
    },
    "endpoints": [
      {"endpointIP": "10.0.1.10", "targetPort": 8080, "weight": 1},
      {"endpointIP": "10.0.1.11", "targetPort": 8080, "weight": 1},
      {"endpointIP": "10.0.1.12", "targetPort": 8080, "weight": 1}
    ]
  }'

# Response (200):
# {"result": "Success"}
```

### Configuration Options

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `sel` | int | `8`, `9`, `10` | `8` | Endpoint selection algorithm. `9` = GPU-aware (uses vLLM metrics) |
| `mode` | int | `4` | - | Must be `4` (FullProxy) for AI Gateway features |
| `backend_protocol` | string | `http1` | - | Must be `http1` for AI Gateway |

**vLLM side requirement:** Start vLLM with the `--enable-metrics` flag to expose the `/metrics` HTTP endpoint:

```bash
python -m vllm.entrypoints.openai.api_server \
  --model meta-llama/Llama-3-8B \
  --enable-metrics \
  --port 8080
```

## Verify

Confirm GPU-aware load balancing is active:

```bash
curl http://loxilb:11111/netlox/v1/config/gpu/status \
  -H "Authorization: Bearer <token>"

# Expected response:
# {"gpu_aware_enabled": true, "active_scrapers": 3}
```

You can also verify the service rule has the correct `sel` value:

```bash
curl http://loxilb:11111/netlox/v1/config/services \
  -H "Authorization: Bearer <token>"
```

Check that your service shows `sel: 9` in the response.

## Troubleshooting

### Scraper Not Connecting

**Symptoms:** GPU-aware selection (`sel: 9`) behaves like round-robin — no differentiation between endpoints.

**Check:**

1. **Metrics endpoint reachable** — Verify from the loxilb host: `curl http://<vllm-ip>:8080/metrics`. Should return Prometheus-format text.
2. **vLLM --enable-metrics flag** — If `/metrics` returns 404, vLLM was started without `--enable-metrics`.
3. **Network connectivity** — Ensure the vLLM serving port (8080) is accessible from the loxilb host. Check security groups and firewall rules.

### Metrics Returning Zero

**Symptoms:** Scraper connects but all endpoints show zero queue depth.

**Check:**

1. **No traffic to vLLM** — Queue depth is zero when vLLM has no pending requests. This is normal under low load.
2. **vLLM version** — Older vLLM versions may not expose `vllm:num_requests_waiting`. Upgrade to a version that supports Prometheus metrics.

### High Queue Depth on All Endpoints

**Symptoms:** All endpoints show high queue depth despite having GPUs available.

**Check:**

1. **Insufficient GPU capacity** — Add more vLLM instances to handle the load.
2. **Enable KV routing** — KV cache-aware routing ([KV Caching](kv-caching.md)) improves cache hit rates, reducing per-request processing time and queue depth.
3. **Model optimization** — Consider using a smaller model or enabling quantization on vLLM to increase throughput per GPU.

## See Also

- [LLM Routing](llm-routing.md) — Three-tier routing architecture (Tier 2 uses vLLM metrics)
- [KV Caching](kv-caching.md) — KV-exact routing configuration (Tier 1.5)
- [Model Load Balancing](model-load-balancing.md) — Per-model endpoint pools
- [Configuration Reference](configuration-reference.md) — All AI Gateway config fields
- [GPU and LLM Catalog API Reference](../reference/api.md#ai-gateway-gpu-and-llm-catalog)
