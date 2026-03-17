# loxilb-enterprise: Unified Gateway Platform

loxilb-enterprise is a high-performance unified gateway built on an eBPF dataplane. It delivers three enterprise capability pillars — **AI Gateway**, **Security Gateway**, and **Network Gateway** — in a single binary designed for Kubernetes and edge environments.

[Get Started in 10 Minutes](getting-started/quickstart.md){ .md-button .md-button--primary }
[Understand the Platform](concepts/unified-gateway.md){ .md-button }

---

## Three Gateway Pillars

<div class="grid cards" markdown>

-   :material-brain:{ .lg .middle } **AI Gateway**

    ---

    Route LLM traffic with KV cache-aware load balancing, vLLM integration, model load balancing, and PD disaggregation — all accelerated by eBPF.

    [:octicons-arrow-right-24: AI Gateway Overview](ai-gateway/overview.md)

-   :material-shield-lock:{ .lg .middle } **Security Gateway**

    ---

    Enforce OPA policies, detect PII with Presidio, filter AI content with LlamaFirewall, rate-limit per endpoint, and secure the dataplane with IPsec and mTLS.

    [:octicons-arrow-right-24: Security Gateway Overview](security-gateway/overview.md)

-   :material-server-network:{ .lg .middle } **Network Gateway**

    ---

    High-performance L4 data plane with egress load balancing, direct server return, NAT64, HTTPS/HTTP2 proxy modes, and SCTP multi-homing.

    [:octicons-arrow-right-24: Network Gateway Overview](network-gateway/overview.md)

</div>

---

## Why loxilb-enterprise?

- **eBPF-accelerated dataplane** — Packet processing in the kernel with no dedicated CPU cores required, delivering line-rate performance for gateway operations
- **Single binary deployment** — All three gateway pillars, control plane, and eBPF dataplane ship as one binary with no external dependencies
- **Kubernetes-native** — Runs as in-cluster or external-to-cluster with kube-loxilb, supporting any CNI (Calico, Flannel, Cilium, Multus)
- **Enterprise security built-in** — OPA policy enforcement, PII detection, AI content safety, IPsec, mTLS, and RBAC-based user management

---

## Quick Links

<div class="grid cards" markdown>

-   **Getting Started**

    ---

    Install the enterprise binary and complete the 10-minute quickstart.

    [:octicons-arrow-right-24: Installation](getting-started/installation.md)

-   **API Reference**

    ---

    Complete REST API documentation for enterprise endpoints.

    [:octicons-arrow-right-24: API Reference](reference/api.md)

-   **Community**

    ---

    Contribute, report issues, or join the discussion.

    [:octicons-arrow-right-24: Contributing](community/contributing.md)

-   **Migrating from Community**

    ---

    Upgrade from community loxilb with full backward compatibility.

    [:octicons-arrow-right-24: Migration Guide](getting-started/migration-from-community.md)

</div>
