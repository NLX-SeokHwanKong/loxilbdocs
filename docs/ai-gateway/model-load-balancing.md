# Model Load Balancing

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## Model-Name Routing

When running multiple LLM models — for example, a large 70B parameter model for complex reasoning and a smaller 8B model for simple queries — you need to route each request to the correct GPU pool based on the requested model. Standard load balancers cannot do this because they do not inspect HTTP body content.

loxilb's AI Gateway solves this with **model-name routing**: the `model_name` field in the LB service configuration creates **per-model endpoint pools**. Multiple LB rules on the same VIP and port can differ only in `model_name`, each pointing to a different set of backend endpoints.

(Source: common/common.go:858)

## How Model Selection Works

When a request arrives at the AI Gateway, loxilb determines the target model in this priority order:

1. **`X-Model` HTTP header** (highest priority) — Allows client-side model selection without modifying the request body.
2. **`"model"` field in JSON body** — The standard OpenAI-compatible API format. sockproxy.c extracts this from the HTTP body using the jsmn JSON parser at C speed.
3. **Wildcard pool** (lowest priority) — If no model-specific rule matches, the request falls through to a rule with no `model_name` set.

This means clients can use the standard OpenAI API format (`"model": "meta-llama/Llama-3-70B"` in the request body) and loxilb automatically routes to the correct GPU pool.

## Configuration

Here is a multi-model configuration with two LB rules on the same VIP, each routing to different GPU tiers:

```yaml
# Rule 1: Llama-3-70B on high-memory GPUs (A100-80GB)
# Source: common/common.go:855-860
serviceArguments:
  vip: "192.168.1.100"
  port: 443
  protocol: "tcp"
  mode: 4                                    # LBModeFullProxy required
  backend_protocol: "http1"
  model_name: "meta-llama/Llama-3-70B"       # Source: common/common.go:858
  sel: 8                                     # CHWBL for conversational cache locality
  llm_type: "chat-interactive"
endpoints:
  - endpointIP: "10.0.1.10"                 # A100-80GB pool
    targetPort: 8080
    weight: 1
  - endpointIP: "10.0.1.11"
    targetPort: 8080
    weight: 1
```

```yaml
# Rule 2: Llama-3-8B on smaller GPUs (L4)
# Source: common/common.go:855-860
serviceArguments:
  vip: "192.168.1.100"
  port: 443
  protocol: "tcp"
  mode: 4
  backend_protocol: "http1"
  model_name: "meta-llama/Llama-3-8B"       # Source: common/common.go:858
  sel: 9                                     # GPU-aware for batch queries
  llm_type: "chat-interactive"
endpoints:
  - endpointIP: "10.0.2.10"                 # L4 pool
    targetPort: 8080
    weight: 1
  - endpointIP: "10.0.2.11"
    targetPort: 8080
    weight: 1
```

```yaml
# Rule 3: Wildcard fallback (catches unmatched models)
serviceArguments:
  vip: "192.168.1.100"
  port: 443
  protocol: "tcp"
  mode: 4
  backend_protocol: "http1"
  # No model_name — wildcard pool
  sel: 8
endpoints:
  - endpointIP: "10.0.3.10"                 # General-purpose pool
    targetPort: 8080
    weight: 1
```

With this configuration, a client sends:

```json
{
  "model": "meta-llama/Llama-3-70B",
  "messages": [{"role": "user", "content": "Explain quantum computing"}]
}
```

loxilb extracts `meta-llama/Llama-3-70B` from the JSON body and routes to the A100-80GB pool (Rule 1). A request for `meta-llama/Llama-3-8B` routes to the L4 pool (Rule 2). An unknown model routes to the wildcard pool (Rule 3).

## llm_type Catalog Profiles

The `llm_type` field selects a **GPU routing catalog profile** that tunes routing parameters for different workload patterns. Examples:

| llm_type | Workload Pattern | Routing Behavior |
|----------|-----------------|------------------|
| `chat-interactive` | Multi-turn conversations | Optimizes for KV cache reuse and low latency |
| `rag-longcontext` | Long-context RAG queries | Optimizes for large prompt processing |

The catalog profile list is defined in `pkg/loxinet/catalog.go`. See [Configuration Reference](configuration-reference.md) for available profiles.

(Source: common/common.go:858)

## See Also

- [LLM Routing](llm-routing.md) — Three-tier routing architecture and model-name routing details
- [KV Caching](kv-caching.md) — KV cache-aware routing for conversational workloads
- [vLLM Integration](vllm-integration.md) — GPU metrics for load-aware selection
- [Configuration Reference](configuration-reference.md) — All AI Gateway config fields
