# Requirements: loxilb-enterprise Documentation Renewal

**Defined:** 2026-03-20
**Core Value:** Every enterprise feature documented with practical REST API examples, option explanations, and complete request/response flows — verified against source code

## v1.2 Requirements

Requirements for Source-Verified Documentation Enhancement. Each page enhanced to match the quality of the 4 reference pages (llm-routing.md, mcp-gateway.md, api-key-management.md, sse-quota-management.md).

**Enhancement patterns applied to every page:**
1. **Mermaid diagrams** — Architecture flowcharts and sequence diagrams
2. **Source-verified fields** — Config fields, API payloads, defaults verified against sockproxy_*.c and swagger.yml
3. **Multiple config options** — Scenario-based deployment options with different use cases
4. **Deep internals** — Technical explanations of internal mechanisms

**Source code locations:**
- Data plane: `/Users/gongseoghwan/go/src/loxilb-enterprise/loxilb-ebpf/common/sockproxy_*.c`
- API spec: `/Users/gongseoghwan/go/src/loxilb-enterprise/api/swagger.yml`

### AI Gateway Enhancement

- [ ] **AIGW-01**: overview.md enhanced with Mermaid architecture diagram, deep internals, source-verified fields
- [ ] **AIGW-02**: kv-caching.md enhanced with Mermaid diagrams, multiple config options, source-verified fields from sockproxy_kv_exact.c
- [ ] **AIGW-03**: vllm-integration.md enhanced with Mermaid diagrams, multiple config options, source-verified fields from sockproxy_metrics.c
- [ ] **AIGW-04**: model-load-balancing.md enhanced with Mermaid diagrams, multiple config options, source-verified fields from sockproxy_routing.c
- [ ] **AIGW-05**: pd-disaggregation.md enhanced with Mermaid diagrams, multiple config options, source-verified fields from sockproxy_pd.c
- [ ] **AIGW-06**: configuration-reference.md enhanced with complete field reference verified against swagger.yml
- [ ] **AIGW-07**: aws-kv-cache.md enhanced with Mermaid diagrams, deployment options, source-verified fields

### Security Gateway Enhancement

- [x] **SECGW-01**: overview.md enhanced with architecture diagram and deep internals
- [x] **SECGW-02**: opa-policy-enforcement.md enhanced with Mermaid diagrams, config options, source-verified fields
- [x] **SECGW-03**: presidio-pii-detection.md enhanced with Mermaid diagrams, config options, source-verified from sockproxy_presidio.c
- [x] **SECGW-04**: llamafirewall.md enhanced with Mermaid diagrams, config options, source-verified from sockproxy_llamafirewall.c
- [x] **SECGW-05**: rate-limiting.md enhanced with Mermaid diagrams, config options, source-verified fields
- [x] **SECGW-06**: ipsec.md enhanced with Mermaid diagrams, config options, source-verified fields
- [ ] **SECGW-07**: mtls.md enhanced with Mermaid diagrams, config options, source-verified from sockproxy_mtls.c
- [ ] **SECGW-08**: syn-flood.md enhanced with Mermaid diagrams, config options, source-verified fields
- [ ] **SECGW-09**: ip-filtering.md enhanced with Mermaid diagrams, config options, source-verified fields
- [ ] **SECGW-10**: secure-dataplane.md enhanced with Mermaid diagrams, deployment options, source-verified fields
- [ ] **SECGW-11**: deployment-scenarios.md enhanced with Mermaid diagrams, multiple scenario options
- [ ] **SECGW-12**: configuration-reference.md enhanced with complete field reference verified against swagger.yml

### Network Gateway Enhancement

- [x] **NETGW-01**: overview.md enhanced with architecture diagram and deep internals
- [x] **NETGW-02**: egress-lb.md enhanced with Mermaid diagrams, config options, source-verified fields
- [x] **NETGW-03**: dsr.md enhanced with Mermaid diagrams, config options, source-verified fields
- [x] **NETGW-04**: nat64.md enhanced with Mermaid diagrams, config options, source-verified fields
- [x] **NETGW-05**: https-proxy.md enhanced with Mermaid diagrams, config options, source-verified from sockproxy_ssl.c
- [x] **NETGW-06**: http2-proxy.md enhanced with Mermaid diagrams, config options, source-verified from sockproxy_h2.c
- [x] **NETGW-07**: sctp-multihoming.md enhanced with Mermaid diagrams, config options, source-verified fields

## Future Requirements

- Document L4 Tracing & Observability deep-dive
- Document Plugins System
- Document Catalog Sync
- Document DB layer
- Korean translations
- QUIC/HTTP3 support documentation

## Out of Scope

| Feature | Reason |
|---------|--------|
| Rewriting the 4 reference pages | Already at target quality — they ARE the reference |
| Community docs enhancement | Separate scope — gradual transition strategy |
| New feature documentation | Only enhancing existing pages, not documenting new features |
| Auto-generated API reference | Manual docs aligned with swagger.yml for now |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AIGW-01 | Phase 9 | Pending |
| AIGW-02 | Phase 9 | Pending |
| AIGW-03 | Phase 9 | Pending |
| AIGW-04 | Phase 9 | Pending |
| AIGW-05 | Phase 9 | Pending |
| AIGW-06 | Phase 9 | Pending |
| AIGW-07 | Phase 9 | Pending |
| SECGW-01 | Phase 10 | Complete |
| SECGW-02 | Phase 10 | Complete |
| SECGW-03 | Phase 10 | Complete |
| SECGW-04 | Phase 10 | Complete |
| SECGW-05 | Phase 10 | Complete |
| SECGW-06 | Phase 10 | Complete |
| SECGW-07 | Phase 11 | Pending |
| SECGW-08 | Phase 11 | Pending |
| SECGW-09 | Phase 11 | Pending |
| SECGW-10 | Phase 11 | Pending |
| SECGW-11 | Phase 11 | Pending |
| SECGW-12 | Phase 11 | Pending |
| NETGW-01 | Phase 12 | Complete |
| NETGW-02 | Phase 12 | Complete |
| NETGW-03 | Phase 12 | Complete |
| NETGW-04 | Phase 12 | Complete |
| NETGW-05 | Phase 12 | Complete |
| NETGW-06 | Phase 12 | Complete |
| NETGW-07 | Phase 12 | Complete |

**Coverage:**
- v1.2 requirements: 26 total
- Mapped to phases: 26
- Unmapped: 0

---
*Requirements defined: 2026-03-20*
*Last updated: 2026-03-20 after roadmap creation — all 26 requirements mapped*
