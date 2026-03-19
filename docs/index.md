# loxilb: eBPF-Powered Gateway for Cloud-Native Infrastructure

**loxilb** is an open-source, eBPF-based cloud-native load balancer and gateway purpose-built for Kubernetes and edge environments. It delivers carrier-grade performance without dedicated CPU cores — and scales from a single cluster to multi-cloud, multi-region deployments.

For AI workloads and production-grade security, **loxilb-enterprise** extends the open-source core with an [AI Gateway](#ai-gateway-the-enterprise-differentiator), advanced Security Gateway, and enterprise capabilities. **Both editions are free to download and use** — commercial support licensing is available when you need it.

[Try loxilb (Open Source)](k3s_quick_start_flannel.md){ .md-button .md-button--primary }
[Try loxilb-enterprise (Free)](getting-started/quickstart.md){ .md-button }

Want production SLAs or dedicated engineering support? [Contact NetLOX](https://netlox.io/business/contact).

---

## Open Source vs. Enterprise

<div class="grid cards" markdown>

-   :material-open-source-initiative:{ .lg .middle } **loxilb — Open Source**

    ---

    The full-featured eBPF load balancer, freely available on GitHub. Production-ready for Kubernetes L4/L7 load balancing, multi-cloud HA, and edge deployments.

    **What's included:**

    - eBPF-accelerated L4 load balancing & NAT
    - Kubernetes Service `type: LoadBalancer` via kube-loxilb
    - BGP, ECMP, DSR, NAT64, GTP, SCTP multi-homing
    - In-cluster & external-to-cluster deployment modes
    - Supports any CNI: Calico, Flannel, Cilium, Multus

    [:octicons-arrow-right-24: Quick Start (k3s + Flannel)](k3s_quick_start_flannel.md)
    [:octicons-arrow-right-24: Architecture](arch.md)

-   :material-crown:{ .lg .middle } **loxilb-enterprise — Free to Use**

    ---

    Everything in loxilb open source, plus the **AI Gateway**, enhanced Security Gateway, and enterprise operations features. **Free to download and run** — optional paid support when you need SLAs.

    **What's added:**

    - :material-brain: **AI Gateway** — KV cache-aware LLM routing, vLLM integration, PD disaggregation
    - :material-shield-lock: **Security Gateway** — OPA policies, PII detection, LlamaFirewall, mTLS
    - :material-server-network: **Network Gateway** — HTTPS/HTTP2 proxy, advanced egress LB
    - Enterprise RBAC, audit logging, and SLA-backed support

    [:octicons-arrow-right-24: Enterprise Quick Start](getting-started/quickstart.md)
    [:octicons-arrow-right-24: Migration from Open Source](getting-started/migration-from-community.md)

</div>

---

## AI Gateway — The Enterprise Differentiator

loxilb-enterprise includes the only eBPF-accelerated AI Gateway designed for production LLM inference infrastructure.

<div class="grid cards" markdown>

-   :material-memory:{ .lg .middle } **KV Cache-Aware Load Balancing**

    ---

    Route inference requests to the GPU node that already holds the KV cache for a given prefix — dramatically cutting time-to-first-token (TTFT).

    [:octicons-arrow-right-24: KV Caching](ai-gateway/kv-caching.md)

-   :material-swap-horizontal:{ .lg .middle } **Prefill / Decode Disaggregation**

    ---

    Separate prefill and decode phases across different node pools to maximize GPU utilization and throughput for large-scale LLM serving.

    [:octicons-arrow-right-24: PD Disaggregation](ai-gateway/pd-disaggregation.md)

-   :material-scale-balance:{ .lg .middle } **Model Load Balancing**

    ---

    Distribute traffic across multiple model replicas or versions with session affinity, weighted routing, and health-aware failover.

    [:octicons-arrow-right-24: Model Load Balancing](ai-gateway/model-load-balancing.md)

-   :material-server:{ .lg .middle } **vLLM Integration**

    ---

    Native integration with vLLM serving engines — no sidecar required. Metric-aware routing based on queue depth and GPU memory pressure.

    [:octicons-arrow-right-24: vLLM Integration](ai-gateway/vllm-integration.md)

</div>

---

## Why loxilb?

- **eBPF dataplane** — Kernel-level packet processing with no dedicated CPU cores; line-rate performance without sacrificing resource efficiency
- **Single binary** — All gateways, control plane, and eBPF programs ship in one binary with zero external runtime dependencies
- **Kubernetes-native** — Full `type: LoadBalancer` support via kube-loxilb on any distribution (k3s, k0s, EKS, OpenShift, microk8s)
- **Cloud & edge ready** — Tested on AWS multi-AZ, multi-cloud HA, bare metal, and edge nodes
- **Open-source foundation** — Core is MIT-licensed, community-driven, and production-proven

---

## Choose Your Path

<div class="grid cards" markdown>

-   **Start with Open Source**

    ---

    Run loxilb in minutes on k3s, k0s, or any Kubernetes cluster. Free forever, no registration required.

    [:octicons-arrow-right-24: k3s + Flannel Quick Start](k3s_quick_start_flannel.md)
    [:octicons-arrow-right-24: k3s + Calico Quick Start](k3s_quick_start_calico.md)
    [:octicons-arrow-right-24: EKS Quick Start](eks-incluster.md)

-   **Try Enterprise Features**

    ---

    Add the AI Gateway and enterprise security to an existing loxilb deployment or start fresh.

    [:octicons-arrow-right-24: Enterprise Installation](getting-started/installation.md)
    [:octicons-arrow-right-24: AI Gateway Overview](ai-gateway/overview.md)
    [:octicons-arrow-right-24: Security Gateway Overview](security-gateway/overview.md)

-   **API & Reference**

    ---

    REST API reference, CLI commands, and configuration options for both open source and enterprise.

    [:octicons-arrow-right-24: API Reference](reference/api.md)
    [:octicons-arrow-right-24: CLI Reference](cmd.md)
    [:octicons-arrow-right-24: Architecture](arch.md)

-   **Get Enterprise Support**

    ---

    Production SLAs, dedicated engineering support, and priority security patches — just like Red Hat for your gateway infrastructure.

    [:octicons-arrow-right-24: Contact NetLOX](https://netlox.io/business/contact)
    [:octicons-arrow-right-24: Community & Contributing](community/contributing.md)

</div>
