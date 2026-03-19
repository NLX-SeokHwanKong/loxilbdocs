# loxilb Documentation — Complete Guide

This guide covers the entire loxilb documentation site — both the **community edition** docs that existing users already know and the **enterprise gateway** docs added for loxilb-enterprise. If you're an existing loxilb user expanding to enterprise features, this is your map.

---

## Quick Start

### Prerequisites

- Python 3.9+
- pip

### Install and Run

```bash
# Install documentation dependencies
pip install -r docs/requirements.txt

# Serve locally with live reload
mkdocs serve

# Open in browser — http://127.0.0.1:8000
```

The site auto-reloads when you edit any file in `docs/`.

### Build for Production

```bash
# Strict build — catches broken links, missing references
mkdocs build --strict

# Output goes to site/ directory
```

---

## Documentation Overview

The site serves two audiences: **community users** running the open-source loxilb load balancer, and **enterprise users** running loxilb-enterprise as a unified gateway platform. All docs live together in one site.

### What's Community vs Enterprise

| Section | Type | Description |
|---------|------|-------------|
| Home (`index.md`) | Enterprise | Unified gateway platform positioning |
| Concepts | Enterprise | Architecture narrative, three-pillar vision |
| Getting Started | Enterprise | Enterprise installation, quickstart, migration |
| AI Gateway | Enterprise | LLM routing, KV caching, vLLM, API keys |
| Security Gateway | Enterprise | OPA, Presidio, LlamaFirewall, IPsec, mTLS |
| Network Gateway | Enterprise | Egress LB, DSR, NAT64, HTTPS/HTTP2 proxy, SCTP |
| Operations | Enterprise | User management, monitoring |
| Reference | Enterprise | Enterprise API (84 endpoints), CLI (23 commands) |
| Deployment Guides | Community | K8s deployment guides (EKS, K3s, K8s, OCP, etc.) |
| Load Balancing & NAT | Community | Core LB concepts, NAT modes, algorithms |
| kube-loxilb | Community | K8s operator, CRDs, service integration |
| HA & BGP | Community | High availability, BGP integration with Calico |
| eBPF & Architecture | Community | eBPF internals, architecture, building from source |
| Performance | Community | Benchmark results and test reports |
| Community CLI & API | Community | Original loxicmd and REST API docs |

Enterprise pages carry a purple **"Enterprise Feature"** admonition to distinguish them visually.

---

## Complete Site Structure

### Enterprise Documentation (New)

```
docs/
├── index.md                        # Home — unified gateway positioning
├── concepts/
│   ├── unified-gateway.md          # Platform architecture narrative
│   └── architecture.md             # Technical architecture
├── getting-started/
│   ├── installation.md             # Docker / K8s / Bare Metal install
│   ├── quickstart.md               # 10-minute quickstart
│   └── migration-from-community.md # Upgrade path from community edition
│
├── ai-gateway/                     # AI Gateway Pillar (10 pages)
│   ├── overview.md                 # Concepts — WHY AI Gateway matters
│   ├── llm-routing.md              # Three-tier routing cascade
│   ├── kv-caching.md               # KV cache-aware load balancing
│   ├── vllm-integration.md         # vLLM scraper + Prometheus metrics
│   ├── model-load-balancing.md     # Per-model endpoint pools
│   ├── pd-disaggregation.md        # Prefill/Decode separation
│   ├── aws-kv-cache.md             # AWS deployment guide
│   ├── api-key-management.md       # API key CRUD
│   ├── sse-quota-management.md     # Server-sent events quota
│   └── configuration-reference.md  # All AI Gateway config fields
│
├── security-gateway/               # Security Gateway Pillar (12 pages)
│   ├── overview.md                 # Three-pillar security architecture
│   ├── opa-policy-enforcement.md   # OPA + Rego policy integration
│   ├── presidio-pii-detection.md   # GDPR/CCPA PII redaction
│   ├── llamafirewall.md            # AI content safety + prompt injection
│   ├── rate-limiting.md            # Per-key, per-tenant, token quota
│   ├── secure-dataplane.md         # IPsec + mTLS + eBPF concepts
│   ├── ipsec.md                    # IPsec tunnel configuration
│   ├── mtls.md                     # mTLS certificate management
│   ├── deployment-scenarios.md     # 4 deployment patterns
│   ├── syn-flood.md                # DDoS protection at eBPF layer
│   ├── ip-filtering.md             # IP-based access control
│   └── configuration-reference.md  # All Security Gateway config fields
│
├── network-gateway/                # Network Gateway Pillar (7 pages)
│   ├── overview.md                 # Architecture + feature table
│   ├── egress-lb.md                # Egress load balancing
│   ├── dsr.md                      # Direct Server Return (L2/L3)
│   ├── nat64.md                    # IPv6-to-IPv4 translation
│   ├── https-proxy.md              # Full proxy, SNI, prefix routing
│   ├── http2-proxy.md              # HTTP/2 + ALPN negotiation
│   └── sctp-multihoming.md         # SCTP for 5G/telco
│
├── operations/                     # Operations (2 pages)
│   ├── user-management.md          # 3 auth modes, RBAC, API keys
│   └── monitoring.md               # Prometheus metrics, Grafana dashboards
│
└── reference/                      # Reference (3 pages)
    ├── api.md                      # Enterprise API (84 endpoints)
    ├── cli.md                      # Enterprise CLI (23 commands)
    └── system-requirements.md      # Hardware/software requirements
```

### Community Documentation (Existing)

These are the original loxilb community docs — all still valid and maintained.

#### Core Concepts
| File | Topic |
|------|-------|
| `lb.md` | What is a Kubernetes external load balancer |
| `lb-algo.md` | Load balancing algorithms (round-robin, hash, etc.) |
| `nat.md` | NAT modes in loxilb (fullNAT, oneArm, DSR, etc.) |
| `ebpf.md` | What is eBPF and how loxilb uses it |
| `loxilbebpf.md` | loxilb eBPF internals deep-dive |
| `arch.md` | loxilb architecture and modules |
| `code.md` | Source code organization |

#### Kubernetes Integration
| File | Topic |
|------|-------|
| `kube-loxilb.md` | kube-loxilb operator — how it works, deployment options |
| `kube-loxilb-url-crds.md` | URL-based CRDs for advanced routing |
| `kube-loxilb-KOR.md` | kube-loxilb guide (Korean) |
| `ccm.md` | Cloud Controller Manager integration |
| `gw-api.md` | Kubernetes Gateway API support |
| `loxilb-ingress.md` | loxilb as Ingress controller |
| `loxilb-nginx-ingress.md` | loxilb with NGINX Ingress |
| `k8s_bgp_policy_crd.md` | BGP policy CRDs for K8s |
| `loxilb-egress.md` | Kubernetes egress gateway |
| `service-sharding.md` | K8s service sharding |
| `service-zones.md` | K8s service zones |
| `ext-ep.md` | External endpoints |

#### Deployment Guides (by Platform)
| Platform | Files |
|----------|-------|
| **K3s** | `k3s_quick_start_flannel.md`, `k3s_quick_start_calico.md`, `k3s_quick_start_incluster.md`, `k3s-multi-master.md`, `k3s-rmq.md` |
| **K8s** | `k8s-flannel-ext.md`, `k8s-flannel-incluster.md` |
| **EKS** | `eks-external.md`, `eks-incluster.md` |
| **K0s** | `k0s_quick_start.md`, `k0s_quick_start_incluster.md` |
| **MicroK8s** | `microk8s_quick_start_incluster.md` |
| **K3K** | `k3k-virtual-cluster.md` |
| **OpenShift** | `rhocp-quickstart-incluster.md` |
| **Multus** | `calico-incluster-multus.md`, `cilium-incluster.md`, `loxilb-incluster-multus.md` |
| **Multi-cloud** | `aws-multi-az.md`, `multi-cloud-ha.md` |
| **Standalone** | `standalone.md` |

#### High Availability & BGP
| File | Topic |
|------|-------|
| `ha-deploy.md` | HA deployment patterns (English) |
| `ha-deploy-KOR.md` | HA deployment patterns (Korean) |
| `integrate_bgp_eng.md` | BGP integration with Calico (English) |
| `integrate_bgp.md` | BGP integration with Calico (Korean) |

#### Features & Protocols
| File | Topic |
|------|-------|
| `https.md` | HTTPS configuration for loxilb API |
| `oauth2.md` | OAuth2 authentication |
| `token.md` | Token-based authentication |
| `proxy-protocol-v2.md` | Proxy Protocol v2 support |
| `gtp.md` | GTP (GPRS Tunneling Protocol) testing |
| `tags.md` | Service tagging |

#### Performance & Testing
| File | Topic |
|------|-------|
| `perf.md` | Performance overview |
| `perf-single.md` | Single-node benchmark results |
| `perf-multi.md` | Multi-node benchmark results |
| `simple_topo.md` | Simple test topology setup |

#### Monitoring & Service Proxy
| File | Topic |
|------|-------|
| `loxilb-incluster-grafana.md` | In-cluster Grafana setup |
| `loxilb-incluster-prod-monitoring.md` | Production monitoring guide |
| `service-proxy-calico.md` | Service proxy with Calico |
| `service-proxy-flannel.md` | Service proxy with Flannel |

#### Reference (Community)
| File | Topic |
|------|-------|
| `cmd.md` | loxicmd CLI reference (community edition) |
| `cmd-dev.md` | loxicmd developer reference |
| `api.md` | Community REST API (SwaggerHub link) |
| `api-dev.md` | API developer reference |
| `requirements.md` | System requirements |

#### Development & Building
| File | Topic |
|------|-------|
| `run.md` | Building loxilb from source |
| `db_setup.md` | Database setup |
| `debugging.md` | Debugging guide |
| `contribute.md` | Contributing guidelines |

---

## Navigation Guide by User Journey

### Existing loxilb User → Enterprise Features

You already know loxilb as a load balancer. Here's how to expand:

1. **Understand the transition**: `concepts/unified-gateway.md` — loxilb is now a unified gateway
2. **Upgrade path**: `getting-started/migration-from-community.md` — step-by-step migration
3. **Pick a pillar** based on your use case:
   - Need LLM traffic routing? → **AI Gateway** tab
   - Need OPA/PII/firewall? → **Security Gateway** tab
   - Need DSR/NAT64/SCTP? → **Network Gateway** tab
4. **Enterprise CLI/API**: `reference/cli.md` and `reference/api.md` — new enterprise-only commands and endpoints extend the community ones you already know

### Community LB User (K8s focus)

Your existing docs are all still here:

1. **kube-loxilb.md** — K8s operator basics (unchanged)
2. **Deployment Guides** — Pick your platform (K3s, EKS, K8s, etc.)
3. **ha-deploy.md** — HA patterns still apply
4. **cmd.md** — Community CLI reference
5. **nat.md** + **lb-algo.md** — Core LB concepts

### Evaluator / CTO

1. **Home** → Three-pillar overview cards
2. **Concepts → Unified Gateway** → Platform vision and architecture
3. Browse each **Gateway Overview** (AI / Security / Network)
4. **Reference → API / CLI** → Integration depth assessment

### DevOps Engineer (Fresh Deploy)

1. **Getting Started → Installation** → Docker / K8s / Bare Metal
2. **Getting Started → Quick Start** → 10-minute enterprise quickstart
3. **Deployment Guides** → Platform-specific guide
4. **Operations → Monitoring** → Prometheus/Grafana setup
5. **Reference → CLI** → Command reference

### Security Architect

1. **Security Gateway → Overview** → Three-pillar security model
2. Feature pages: OPA, Presidio, LlamaFirewall, IPsec, mTLS
3. **Deployment Scenarios** → Choose architecture pattern
4. **Reference → API** → Security endpoint details

### Network Engineer

1. **Network Gateway → Overview** → Feature table, architecture
2. Feature pages: Egress LB, DSR, NAT64, proxy modes, SCTP
3. Community: **nat.md**, **lb-algo.md** — Core NAT/LB concepts
4. Community: **ha-deploy.md** — HA deployment patterns
5. **Reference → CLI** → Network commands

---

## Community ↔ Enterprise Feature Map

For existing users, here's how community features connect to enterprise equivalents:

| Community Feature | Community Doc | Enterprise Extension | Enterprise Doc |
|---|---|---|---|
| Load balancing | `lb.md`, `nat.md` | Egress LB, DSR, NAT64 | `network-gateway/` |
| HTTPS support | `https.md` | HTTPS/HTTP2 proxy modes | `network-gateway/https-proxy.md` |
| CLI (loxicmd) | `cmd.md` | Enterprise CLI (23 extra cmds) | `reference/cli.md` |
| REST API | `api.md` | Enterprise API (84 endpoints) | `reference/api.md` |
| Grafana monitoring | `loxilb-incluster-grafana.md` | Enterprise Prometheus metrics | `operations/monitoring.md` |
| OAuth2 | `oauth2.md` | 3-mode auth + RBAC | `operations/user-management.md` |
| K8s ingress | `loxilb-ingress.md` | AI-aware LLM routing | `ai-gateway/llm-routing.md` |
| K8s egress | `loxilb-egress.md` | Enterprise egress LB | `network-gateway/egress-lb.md` |
| eBPF dataplane | `ebpf.md` | eBPF + IPsec + mTLS | `security-gateway/secure-dataplane.md` |
| HA deployment | `ha-deploy.md` | Enterprise deployment scenarios | `security-gateway/deployment-scenarios.md` |
| — (new) | — | OPA policy enforcement | `security-gateway/opa-policy-enforcement.md` |
| — (new) | — | PII detection (Presidio) | `security-gateway/presidio-pii-detection.md` |
| — (new) | — | AI content safety (LlamaFirewall) | `security-gateway/llamafirewall.md` |
| — (new) | — | KV cache-aware LLM routing | `ai-gateway/kv-caching.md` |
| — (new) | — | vLLM integration | `ai-gateway/vllm-integration.md` |

---

## Documentation Patterns

### Enterprise Admonition

Enterprise-only pages start with a purple admonition:

```markdown
!!! enterprise "Enterprise Feature"
    This feature is available in loxilb-enterprise. [Get started →](../getting-started/installation.md)
```

Community pages do **not** have this — they work with both editions.

### Source-Traced Configuration (Enterprise)

Enterprise config examples include source annotations:

```markdown
<!-- Source: pkg/loxinet/ai_kv_router.go:142 -->
```

This lets you verify configs against the actual loxilb-enterprise source at `3rdparty/loxilb-enterprise/`.

### Page Structure (Enterprise)

1. **Enterprise admonition** — identifies enterprise-only features
2. **Concept explanation** — WHY this feature exists
3. **Architecture diagram** — Mermaid flowchart
4. **Configuration** — Real YAML/CLI examples with source annotations
5. **Tabbed methods** — loxicmd / REST API / Kubernetes CRD
6. **Verification** — How to confirm it works
7. **Cross-references** — Links to related features

### Tabbed Content

Multi-method configuration uses Material tabs:

```markdown
=== "loxicmd"
    ```bash
    loxicmd create lb 10.10.10.1 --tcp=80:8080 --endpoints=10.0.0.1:1
    ```

=== "REST API"
    ```bash
    curl -X POST http://localhost:11111/netlox/v1/config/loadbalancer ...
    ```

=== "Kubernetes CRD"
    ```yaml
    apiVersion: loxilb.io/v1
    kind: LoxiLBService
    ...
    ```
```

---

## Verifying the Documentation

### Automated Checks

```bash
# 1. Build check — catches config errors, missing files, broken internal refs
mkdocs build --strict

# 2. Link check (if lychee is installed)
lychee docs/**/*.md --exclude-mail

# 3. Prose linting (if vale is installed)
vale docs/
```

### Manual Verification Checklist

| What to Check | How |
|---|---|
| Navigation tabs | Click through all tabs — AI/Security/Network Gateway |
| Community pages load | Click Deployment Guides, verify old K3s/EKS/K8s guides render |
| Cross-links | Click links between pillars and between community ↔ enterprise |
| Mermaid diagrams | Verify architecture, traffic flow, deployment diagrams render |
| Code blocks | Check syntax highlighting and copy button |
| Tabbed content | Switch between loxicmd / REST API / K8s CRD tabs |
| Search | Search for "KV cache", "OPA", "DSR", "kube-loxilb" |
| Dark mode | Toggle dark/light mode |
| Enterprise admonitions | Purple shield on enterprise pages, absent on community pages |
| Migration guide | `getting-started/migration-from-community.md` flows correctly |

### Verify Configs Against Source

```bash
# Enterprise config key exists in source
grep -r "kv_cache_routing" 3rdparty/loxilb-enterprise/pkg/loxinet/

# API endpoint exists in swagger
grep "/config/aigateway" 3rdparty/loxilb-enterprise/api/swagger.yml
```

---

## Editing Documentation

### Adding a New Page

1. Create the markdown file in the appropriate directory
2. Add it to `mkdocs.yml` nav section
3. Follow the page structure pattern for enterprise pages
4. Run `mkdocs serve` to verify

### Editing Existing Pages

1. Find the file in `docs/` (structure mirrors the nav)
2. Edit the markdown — `mkdocs serve` auto-reloads
3. Run `mkdocs build --strict` before committing

### Configuration Files

| File | Purpose |
|---|---|
| `mkdocs.yml` | Site config — nav, theme, plugins, extensions |
| `docs/requirements.txt` | Python dependencies for MkDocs |
| `overrides/` | Custom theme overrides |
| `docs/stylesheets/extra.css` | Custom CSS (enterprise admonitions) |

---

## Versioning

The site uses [mike](https://github.com/jimporter/mike) for version management:

```bash
# Deploy a version
mike deploy v1.0 latest --update-aliases

# List deployed versions
mike list

# Serve versioned site locally
mike serve
```

---

## Key Files Reference

| File | Description |
|---|---|
| `mkdocs.yml` | MkDocs config — nav, theme, plugins, extensions |
| `docs/index.md` | Home page with three-pillar gateway cards |
| `docs/concepts/unified-gateway.md` | Platform architecture narrative |
| `docs/getting-started/quickstart.md` | 10-minute enterprise quickstart |
| `docs/getting-started/migration-from-community.md` | Community → Enterprise upgrade path |
| `docs/reference/api.md` | Enterprise API reference (84 endpoints) |
| `docs/reference/cli.md` | Enterprise CLI reference (23 commands) |
| `docs/cmd.md` | Community loxicmd reference (original) |
| `docs/api.md` | Community REST API (SwaggerHub) |
| `docs/kube-loxilb.md` | kube-loxilb K8s operator guide |
| `docs/ha-deploy.md` | HA deployment patterns |
| `docs/nat.md` | NAT modes in loxilb |
| `docs/ebpf.md` | eBPF dataplane concepts |
| `docs/operations/monitoring.md` | Enterprise Prometheus/Grafana setup |
| `docs/stylesheets/extra.css` | Enterprise admonition CSS |
| `3rdparty/loxilb-enterprise/` | Enterprise source code |
| `3rdparty/loxilb-enterprise/api/swagger.yml` | API spec (source of truth) |
