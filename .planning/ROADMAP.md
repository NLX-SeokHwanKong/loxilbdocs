# Roadmap: loxilb-enterprise Documentation Renewal

## Overview

Five phases build the enterprise documentation site in strict dependency order. Phase 1 establishes the structural and visual conventions that every other phase depends on. Phases 2 and 3 document the two headline enterprise pillars (AI Gateway and Security Gateway) — the primary differentiators that drive evaluation and procurement decisions. Phase 4 completes the third pillar (Network Gateway) and operations layer. Phase 5 caps with comprehensive reference material, which can only be complete once all features are documented. The result is a customer-ready docs site at docs.netlox.io/latest demonstrating enterprise-grade depth and source-verified accuracy.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Establish MkDocs structure, nav hierarchy, positioning anchors, and CI toolchain before any feature content is written
- [ ] **Phase 2: AI Gateway** - Document the headline enterprise differentiator — LLM routing, KV caching, vLLM integration, model load balancing — with source-verified configs
- [ ] **Phase 3: Security Gateway** - Document the procurement-critical security pillar — OPA, Presidio, LlamaFirewall, rate limiting, secure dataplane — with real configs
- [ ] **Phase 4: Network Gateway and Operations** - Complete the third gateway pillar, operations layer (user management, monitoring), and enterprise Getting Started guide
- [ ] **Phase 5: Reference** - Deliver comprehensive enterprise API and CLI reference, achievable only after all features are documented

## Phase Details

### Phase 1: Foundation
**Goal**: Evaluators can navigate a correctly structured docs site with enterprise gateway positioning, clear three-pillar tabs, and all enterprise visual conventions in place — before any feature content is written
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04
**Success Criteria** (what must be TRUE):
  1. The docs site renders with three top-level tabs (AI Gateway, Security Gateway, Network Gateway) and all enterprise sections visible as navigable stubs
  2. The home page (index.md) opens with unified gateway platform positioning — not "eBPF-based load balancer" framing
  3. A reader can reach the enterprise Getting Started guide from the home page in one click and complete the 10-minute quickstart against the enterprise binary
  4. Every enterprise-only page carries a visible "Enterprise Feature" admonition that distinguishes it from community content
  5. The CI pipeline passes `mkdocs build --strict`, prose linting, and broken-link detection on every push
**Plans**: 4 plans

Plans:
- [ ] 01-01-PLAN.md — Restructure mkdocs.yml nav with three-pillar tabs, enable Material features, create all enterprise stub pages (Wave 1)
- [ ] 01-02-PLAN.md — Write index.md enterprise positioning and concepts/unified-gateway.md architectural narrative (Wave 2)
- [ ] 01-03-PLAN.md — Write enterprise Getting Started guide: installation, quickstart, migration from community (Wave 2)
- [ ] 01-04-PLAN.md — Update CI pipeline: actions v4/v5, pinned requirements.txt, mkdocs build --strict, vale, lychee (Wave 3)

### Phase 2: AI Gateway
**Goal**: Enterprise evaluators and architects can read complete AI Gateway documentation — with conceptual explanations written for networking engineers, and every configuration example traced to enterprise source code
**Depends on**: Phase 1
**Requirements**: AIGW-01, AIGW-02, AIGW-03, AIGW-04, AIGW-05, AIGW-06, AIGW-07, AIGW-08
**Success Criteria** (what must be TRUE):
  1. A networking engineer unfamiliar with LLMs can read the AI Gateway concepts page and understand what KV caching and vLLM integration solve at the gateway layer
  2. A DevOps engineer can follow the LLM routing and KV cache configuration pages to deploy a working AI Gateway setup, using only the documented YAML — with every config key annotated with its source file and line from ai_gateway_dp.go or ai_kv_router.go
  3. The AI Security page explains LlamaFirewall and Presidio integration in context of the AI traffic flow, with a working configuration example
  4. Advanced deployment patterns (PD disaggregation, AWS KV cache-aware deployment, API key management, SSE quota management) each have their own documented page with prerequisite explanation
**Plans**: 4 plans

Plans:
- [ ] 02-01-PLAN.md — Write AI Gateway concepts (overview.md) and LLM Routing architecture (llm-routing.md) for networking engineers (Wave 1)
- [ ] 02-02-PLAN.md — Document KV Cache routing, vLLM integration, and model load balancing with source-traced configs (Wave 2)
- [ ] 02-03-PLAN.md — Document AI Security: LlamaFirewall and Presidio PII detection in AI traffic context (Wave 2)
- [ ] 02-04-PLAN.md — Document advanced features: PD disaggregation, AWS KV cache, API key management, SSE quota, and configuration reference (Wave 3)

### Phase 3: Security Gateway
**Goal**: Enterprise security teams and architects can read complete Security Gateway documentation covering every procurement checklist item — OPA policy enforcement, PII detection, AI content safety, rate limiting, and secure dataplane — with configs traced to enterprise source
**Depends on**: Phase 1
**Requirements**: SECG-01, SECG-02, SECG-03, SECG-04, SECG-05, SECG-06, SECG-07, SECG-08, SECG-09, SECG-10
**Success Criteria** (what must be TRUE):
  1. A security architect can find and read an OPA policy enforcement page that explains Rego for networking engineers and includes a real policy example traced to pkg/opa/ source
  2. A compliance officer evaluating GDPR/CCPA requirements can read the Presidio PII detection page and understand how gateway-layer PII interception works, with configuration from pkg/presidio/
  3. A security reviewer can read the LlamaFirewall page and find a documented threat model (prompt injection, content filtering) before reaching any configuration block
  4. A DevOps engineer can configure rate limiting per endpoint using only the documented YAML, traced to pkg/ratelimit/
  5. An architect reviewing the secure dataplane overview can understand how IPsec, mTLS, and eBPF combine, with separate deep-dive pages for IPsec and mTLS configuration
**Plans**: 5 plans

Plans:
- [ ] 03-01-PLAN.md — Write Security Gateway overview landing page and secure dataplane concepts page (Wave 1)
- [ ] 03-02-PLAN.md — Write OPA policy enforcement page and enhance Presidio PII detection page (Wave 2)
- [ ] 03-03-PLAN.md — Enhance LlamaFirewall page with Security Gateway cross-references (Wave 2)
- [ ] 03-04-PLAN.md — Write rate limiting, SYN flood protection, and IP filtering pages (Wave 2)
- [ ] 03-05-PLAN.md — Write IPsec, mTLS, deployment scenarios, and configuration reference pages (Wave 3)

### Phase 4: Network Gateway and Operations
**Goal**: The Network Gateway pillar is documented as the high-performance data plane foundation of the unified gateway, operators can manage users and monitor the system end-to-end, and a complete enterprise Getting Started path exists for the full product
**Depends on**: Phase 1
**Requirements**: NETG-01, NETG-02, NETG-03, NETG-04, NETG-05, NETG-06, OPS-01, OPS-02
**Success Criteria** (what must be TRUE):
  1. A network architect can find documentation for each advanced network feature (Egress LB, DSR, NAT64, HTTPS proxy modes, HTTP/2 proxy, SCTP multi-homing) with configuration examples
  2. An enterprise administrator can follow the user management page to configure RBAC, namespace isolation, and multi-tenant access control using configs from pkg/user/
  3. An SRE can follow the monitoring setup page to configure Prometheus metrics and import Grafana dashboards for enterprise features
**Plans**: 4 plans

Plans:
- [ ] 04-01-PLAN.md — Write Network Gateway overview, Egress LB, DSR, and NAT64 pages (Wave 1)
- [ ] 04-02-PLAN.md — Write HTTPS proxy modes, HTTP/2 proxy, and SCTP multi-homing pages (Wave 1)
- [ ] 04-03-PLAN.md — Write User Management page: three auth modes, RBAC, password policy, API keys (Wave 2)
- [ ] 04-04-PLAN.md — Write Monitoring Setup page: Prometheus metrics, scrape config, Grafana guidance (Wave 2)

### Phase 5: Reference
**Goal**: Enterprise engineers have a complete, authoritative reference for the enterprise API and CLI — covering all endpoints and commands added in the enterprise binary — enabling production operations and integration without support escalation
**Depends on**: Phases 2, 3, 4
**Requirements**: REF-01, REF-02
**Success Criteria** (what must be TRUE):
  1. A developer integrating with the enterprise API can find every enterprise endpoint (including user management, plugin, and catalog sync APIs not in community SwaggerHub) documented with request/response examples in the API reference
  2. An operator can look up every enterprise CLI command and flag in the CLI reference without consulting source code
**Plans**: 2 plans

Plans:
- [ ] 05-01-PLAN.md — Write enterprise API reference: all enterprise-only endpoints from swagger.yml with authentication flow, request/response examples, and source annotations (Wave 1)
- [ ] 05-02-PLAN.md — Write enterprise CLI reference: all loxicmd-enterprise commands with global flags, authentication workflow, enterprise badges, and usage examples (Wave 1)

## Progress

**Execution Order:**
Phases execute in dependency order: 1 → 2 → 3 → 4 → 5
Note: Phases 2, 3, and 4 all depend on Phase 1 and can be parallelized after Phase 1 completes.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/4 | Not started | - |
| 2. AI Gateway | 0/4 | Not started | - |
| 3. Security Gateway | 0/5 | Not started | - |
| 4. Network Gateway and Operations | 0/4 | Not started | - |
| 5. Reference | 0/2 | Not started | - |
