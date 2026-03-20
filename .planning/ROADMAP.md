# Roadmap: loxilb-enterprise Documentation Renewal

## Milestones

- ✅ **v1.0 Documentation Renewal** — Phases 1-5 (shipped 2026-03-18)
- ✅ **v1.1 Practical API Enhancement** — Phases 6-8 (shipped 2026-03-18)
- 🚧 **v1.2 Source-Verified Documentation Enhancement** — Phases 9-12 (in progress)

## Phases

<details>
<summary>✅ v1.0 Documentation Renewal (Phases 1-5) — SHIPPED 2026-03-18</summary>

- [x] Phase 1: Foundation (4/4 plans) — MkDocs structure, nav, positioning, CI
- [x] Phase 2: AI Gateway (4/4 plans) — LLM routing, KV cache, vLLM, PD disagg, API keys
- [x] Phase 3: Security Gateway (5/5 plans) — OPA, Presidio, LlamaFirewall, rate limiting, IPsec/mTLS
- [x] Phase 4: Network Gateway & Operations (4/4 plans) — Egress LB, DSR, NAT64, proxies, SCTP, user mgmt, monitoring
- [x] Phase 5: Reference (2/2 plans) — Enterprise API reference (84 endpoints), CLI reference (23 commands)

**Total:** 5 phases, 19 plans, 32 requirements satisfied
**Archives:** `milestones/v1.0-ROADMAP.md`, `milestones/v1.0-REQUIREMENTS.md`, `milestones/v1.0-MILESTONE-AUDIT.md`

</details>

<details>
<summary>✅ v1.1 Practical API Enhancement (Phases 6-8) — SHIPPED 2026-03-18</summary>

- [x] Phase 6: AI Gateway API Enhancement (3/3 plans) — 10 pages rewritten to REST API-first format
- [x] Phase 7: Security Gateway API Enhancement (3/3 plans) — 12 pages rewritten to REST API-first format
- [x] Phase 8: Network Gateway API Enhancement (3/3 plans) — 7 pages rewritten to REST API-first format

**Total:** 3 phases, 9 plans, 15 requirements satisfied
**Archives:** `milestones/v1.1-ROADMAP.md`, `milestones/v1.1-REQUIREMENTS.md`, `milestones/v1.1-MILESTONE-AUDIT.md`

</details>

### 🚧 v1.2 Source-Verified Documentation Enhancement (In Progress)

**Milestone Goal:** Enhance all 26 remaining gateway pages to match the depth and quality of the 4 reference pages, with every technical claim verified against sockproxy_*.c source code and swagger.yml.

**Execution note:** Phases 9, 10, 11, and 12 cover independent gateway pillars. Phases 10 and 11 cover the same pillar split by topic cluster. All four phases can be planned and executed concurrently.

- [ ] **Phase 9: AI Gateway Enhancement** — 7 pages elevated to reference quality with Mermaid diagrams, source-verified fields, and deep internals
- [ ] **Phase 10: Security Gateway Enhancement (Part 1)** — 6 pages (overview + threat detection stack) elevated to reference quality
- [ ] **Phase 11: Security Gateway Enhancement (Part 2)** — 6 pages (transport security + deployment) elevated to reference quality
- [ ] **Phase 12: Network Gateway Enhancement** — 7 pages elevated to reference quality with Mermaid diagrams and source-verified fields

## Phase Details

### Phase 9: AI Gateway Enhancement
**Goal**: All 7 AI Gateway pages match the quality of llm-routing.md — Mermaid diagrams, source-verified config fields, multiple deployment options, and deep internal mechanism explanations
**Depends on**: Nothing (independent of Phases 10-12)
**Requirements**: AIGW-01, AIGW-02, AIGW-03, AIGW-04, AIGW-05, AIGW-06, AIGW-07
**Success Criteria** (what must be TRUE):
  1. Every AI Gateway page has at least one Mermaid architecture or sequence diagram showing how the feature works internally
  2. Every config field in every AI Gateway page is verified against sockproxy_*.c or swagger.yml — no undocumented defaults or invented field names
  3. Each AI Gateway feature page offers at least two distinct deployment/configuration scenarios with concrete examples
  4. overview.md explains the full AI Gateway data plane flow so an operator understands request lifecycle without reading source code
  5. configuration-reference.md is a complete field reference — every field from swagger.yml is present with type, valid values, default, and description
**Plans**: 3 plans

Plans:
- [x] 09-01: Enhance AI Gateway overview, KV caching, and vLLM integration
- [x] 09-02: Enhance model load balancing, PD disaggregation, and AWS KV cache
- [ ] 09-03: Enhance AI Gateway configuration reference

### Phase 10: Security Gateway Enhancement (Part 1)
**Goal**: The first 6 Security Gateway pages — overview, OPA policy enforcement, Presidio PII detection, LlamaFirewall, rate limiting, and IPsec — reach reference quality with Mermaid diagrams, source-verified fields, and deep internals
**Depends on**: Nothing (independent of Phases 9, 11, 12)
**Requirements**: SECGW-01, SECGW-02, SECGW-03, SECGW-04, SECGW-05, SECGW-06
**Success Criteria** (what must be TRUE):
  1. overview.md presents a complete Security Gateway architecture diagram showing how OPA, Presidio, LlamaFirewall, rate limiting, and transport security interact in the request pipeline
  2. Every policy enforcement page (OPA, Presidio, LlamaFirewall) has a sequence diagram showing the exact evaluation path from request arrival to policy decision
  3. All config fields for OPA, Presidio, LlamaFirewall, and rate limiting are verified against their respective sockproxy_*.c source files — no invented field names
  4. Each page offers at least two configuration scenarios (e.g., strict vs. permissive policy, per-key vs. per-tenant rate limiting)
**Plans**: TBD

Plans:
- [ ] 10-01: Enhance Security Gateway overview and OPA policy enforcement
- [ ] 10-02: Enhance Presidio PII detection and LlamaFirewall
- [ ] 10-03: Enhance rate limiting and IPsec

### Phase 11: Security Gateway Enhancement (Part 2)
**Goal**: The remaining 6 Security Gateway pages — mTLS, SYN flood protection, IP filtering, secure dataplane, deployment scenarios, and configuration reference — reach reference quality with Mermaid diagrams, source-verified fields, and deep internals
**Depends on**: Nothing (independent of Phases 9, 10, 12; can run concurrently with Phase 10)
**Requirements**: SECGW-07, SECGW-08, SECGW-09, SECGW-10, SECGW-11, SECGW-12
**Success Criteria** (what must be TRUE):
  1. mtls.md has a sequence diagram showing the full mTLS handshake as implemented in sockproxy_mtls.c, including certificate validation steps
  2. deployment-scenarios.md presents multiple complete reference architectures as Mermaid diagrams — operators can choose a topology and see the exact API config for it
  3. All config fields for mTLS, SYN flood, and IP filtering are verified against source — defaults and valid ranges match implementation
  4. configuration-reference.md is a complete field reference for all Security Gateway config verified against swagger.yml
**Plans**: TBD

Plans:
- [ ] 11-01: Enhance mTLS and SYN flood protection
- [ ] 11-02: Enhance IP filtering and secure dataplane
- [ ] 11-03: Enhance deployment scenarios and Security Gateway configuration reference

### Phase 12: Network Gateway Enhancement
**Goal**: All 7 Network Gateway pages reach reference quality — Mermaid diagrams showing data-plane forwarding paths, source-verified config fields from sockproxy_ssl.c and sockproxy_h2.c, and scenario-based deployment options
**Depends on**: Nothing (independent of Phases 9, 10, 11)
**Requirements**: NETGW-01, NETGW-02, NETGW-03, NETGW-04, NETGW-05, NETGW-06, NETGW-07
**Success Criteria** (what must be TRUE):
  1. overview.md has an architecture diagram showing how Network Gateway fits into the loxilb-enterprise data plane and the relationship between egress LB, DSR, NAT64, and proxy features
  2. Every Network Gateway page has a Mermaid diagram showing the packet/connection forwarding path for that specific feature
  3. https-proxy.md and http2-proxy.md config fields are verified against sockproxy_ssl.c and sockproxy_h2.c respectively — TLS termination details, cipher suites, and connection upgrade behavior match implementation
  4. Each Network Gateway feature page offers at least two deployment configurations with distinct use-case framing (e.g., egress LB for east-west vs. north-south traffic)
**Plans**: TBD

Plans:
- [ ] 12-01: Enhance Network Gateway overview, egress LB, and DSR
- [ ] 12-02: Enhance NAT64, HTTPS proxy, and HTTP2 proxy
- [ ] 12-03: Enhance SCTP multihoming

## Progress

**Execution Order:**
Phases 9-12 are independent and can execute concurrently. Recommended order if sequential: 9 → 10 → 11 → 12.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 4/4 | Complete | 2026-03-17 |
| 2. AI Gateway | v1.0 | 4/4 | Complete | 2026-03-17 |
| 3. Security Gateway | v1.0 | 5/5 | Complete | 2026-03-17 |
| 4. Network Gateway & Operations | v1.0 | 4/4 | Complete | 2026-03-17 |
| 5. Reference | v1.0 | 2/2 | Complete | 2026-03-17 |
| 6. AI Gateway API Enhancement | v1.1 | 3/3 | Complete | 2026-03-18 |
| 7. Security Gateway API Enhancement | v1.1 | 3/3 | Complete | 2026-03-18 |
| 8. Network Gateway API Enhancement | v1.1 | 3/3 | Complete | 2026-03-18 |
| 9. AI Gateway Enhancement | v1.2 | 2/3 | In Progress | - |
| 10. Security Gateway Enhancement (Part 1) | v1.2 | 0/3 | Not started | - |
| 11. Security Gateway Enhancement (Part 2) | v1.2 | 0/3 | Not started | - |
| 12. Network Gateway Enhancement | v1.2 | 0/3 | Not started | - |
