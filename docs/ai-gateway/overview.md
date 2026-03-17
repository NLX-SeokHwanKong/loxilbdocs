# AI Gateway Overview

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is the AI Gateway?

You know how a load balancer distributes HTTP traffic across web servers. An AI Gateway does the same for Large Language Model (LLM) inference traffic — but with awareness of GPU memory state, model placement, and streaming response patterns that standard L4/L7 load balancers cannot handle.

The core problem is that LLM inference is **stateful**, not stateless like web traffic. When a GPU processes a prompt, it builds a **KV cache** (key-value attention matrices) in its VRAM — essentially a memory of the conversation context. If the next request in that conversation lands on a different GPU, that GPU must rebuild the entire KV cache from scratch. This causes a **3-5x latency increase** on every cache miss, turning a sub-second response into a multi-second wait.

loxilb's AI Gateway solves this with **eBPF-accelerated L7 proxy routing** (FullProxy mode) that is KV cache-aware. Instead of blindly round-robining requests across GPUs, loxilb routes each prompt to the GPU that already holds the relevant KV cache blocks — preserving cache locality while maintaining load balance across the GPU fleet.

## Why eBPF for AI Traffic?

Networking engineers are familiar with eBPF for high-performance packet processing. loxilb applies the same principle to AI traffic:

- **eBPF TC hook** handles L4 fast-path operations: connection tracking (conntrack) and NAT map lookups. This is the same eBPF acceleration used for standard load balancing.

- **sockproxy.c** (C user-space) performs L7 HTTP body parsing. It extracts the model name, API key, and prompt content from incoming `/v1/chat/completions` requests using the jsmn JSON parser — all in C for minimal overhead.

- **CGO bridge pattern**: The C hot-path calls Go logic for enforcement decisions (API key validation, rate limiting, AI security scanning). This keeps enforcement at data-plane speed while business logic stays in testable Go code. Each bridge function follows the same pattern: C sockproxy calls `//export llb_ai_*()` in Go, Go runs pure logic, returns a `C.int` decision.

This architecture means that API key validation, rate limiting, and security scanning all happen **before** traffic reaches the backend LLM — at data-plane speed, not application-layer speed.

(Source: architecture from packet-processing-pipeline.md, ai_gateway_dp.go, ai_security.go CGO bridge pattern)

## Key Capabilities

The AI Gateway provides the following enterprise features, each documented on its own page:

- **KV Cache-Aware Routing** — Route requests to the GPU that already has the relevant KV cache blocks, eliminating cold-start latency penalties. See [KV Caching](kv-caching.md).

- **vLLM Integration & GPU-Aware Load Balancing** — Scrape real-time GPU metrics (queue depth, cache usage) from vLLM instances for intelligent endpoint selection. See [vLLM Integration](vllm-integration.md) and [Model Load Balancing](model-load-balancing.md).

- **API Key Management & Rate Limiting** — Per-key and per-tenant rate limiting enforced at the data plane. Keys are validated before traffic reaches backends. See [API Key Management](api-key-management.md).

- **AI Security (LlamaFirewall + Presidio)** — Inline prompt inspection for injection attacks, credential leakage, and PII detection. See [LlamaFirewall](../security-gateway/llamafirewall.md) and [PII Detection with Presidio](../security-gateway/presidio-pii-detection.md).

- **SSE Streaming & Token Quota** — Server-Sent Events support with per-tenant token quota management for streaming LLM responses. See [SSE Quota Management](sse-quota-management.md).

- **PD Disaggregation** — Separate prefill (compute-bound) and decode (memory-bound) phases onto different GPU pools for 2-3x throughput improvement. See [PD Disaggregation](pd-disaggregation.md).

## Traffic Flow Overview

The following diagram shows the complete request path through the AI Gateway:

```mermaid
sequenceDiagram
    participant Client
    participant eBPF as eBPF TC Hook
    participant Sock as sockproxy.c (L7)
    participant Go as Go Logic (CGO)
    participant LF as LlamaFirewall (gRPC)
    participant vLLM as Backend vLLM

    Client->>eBPF: POST /v1/chat/completions → VIP:443
    eBPF->>Sock: L4 conntrack → forward to sockproxy
    Sock->>Go: Extract X-API-Key → llb_ai_validate_key()
    Go-->>Sock: allow / 401 / 403
    Sock->>Go: llb_ai_ratelimit_check()
    Go-->>Sock: allow / 429 + retry_after
    opt LlamaFirewall enabled
        Sock->>LF: llb_llamafirewall_scan() (gRPC)
        LF-->>Sock: allow / block / HITL
    end
    Sock->>Sock: Endpoint selection (KV-exact → GPU-aware → fallback)
    Sock->>vLLM: Forward request
    vLLM-->>Client: SSE stream (data: tokens...)
    Note over Sock,Go: On stream completion → llb_ai_token_quota_consume()
```

(Source: ai_gateway_dp.go:195-329 traffic flow)

## Prerequisites

Before configuring any AI Gateway feature, ensure the following:

!!! warning "Required: FullProxy Mode"
    All AI Gateway features require `mode: 4` (LBModeFullProxy) and `backend_protocol: "http1"`. Other LB modes perform L4 load balancing only and cannot inspect HTTP bodies for model routing, API key validation, or KV cache matching.

    Source: common/common.go:885

- **loxilb-enterprise binary** — The AI Gateway is an enterprise-only feature. See [Installation](../getting-started/installation.md) for setup instructions.
- **FullProxy mode** — Set `mode: 4` on your LB service. This enables L7 proxy mode with HTTP body inspection, unlike L4 DNAT modes.
- **HTTP/1 backend protocol** — Set `backend_protocol: "http1"` for all AI Gateway services. HTTP/2 is not supported for AI Gateway features.

## LB Selection Modes for LLM Workloads

loxilb provides three load balancing selection modes optimized for LLM traffic. Choose based on your workload pattern:

| Mode | `sel` Value | Name | Use Case |
|------|-------------|------|----------|
| Consistent Hash with Bounded Loads | `8` | LbSelCHWBL | **Default for KV cache routing.** Routes based on consistent hash, preserving KV cache locality. Best for conversational workloads where cache reuse matters. |
| GPU-Aware | `9` | LbSelGPUAware | Uses real-time GPU queue depth and cache usage metrics from vLLM. Best for batch/independent queries where throughput matters more than cache locality. |
| Weighted Round-Robin with Hash | `10` | LbSelWRRHash | Combines weighted round-robin with hash-based distribution. For mixed workloads or when transitioning from standard LB. |

(Source: common/common.go:674-699)

## Next Steps

- **New to AI Gateway?** Start with [LLM Routing](llm-routing.md) to understand the three-tier routing architecture.
- **Setting up KV cache routing?** See [KV Caching](kv-caching.md) for configuration.
- **Deploying on AWS?** See [AWS KV Cache Deployment](aws-kv-cache.md) for cloud-specific guidance.
- **Need the full config reference?** See [Configuration Reference](configuration-reference.md) for all fields.
