# Requirements: loxilb-enterprise Documentation Renewal

**Defined:** 2026-03-17
**Core Value:** Every enterprise feature documented with deep concepts, real configs from source, and practical examples — perfectly synchronized with loxilb-enterprise implementation.

## v1 Requirements

Requirements for customer-ready v1 documentation at docs.netlox.io/latest.

### Foundation

- [ ] **FOUND-01**: Restructure MkDocs nav with three-pillar tabs (AI Gateway / Security Gateway / Network Gateway)
- [ ] **FOUND-02**: Add MkDocs Material features (navigation.tabs, content.code.annotate, pymdownx.tabbed, tags plugin)
- [ ] **FOUND-03**: Create new index.md positioning loxilb-enterprise as unified gateway platform
- [ ] **FOUND-04**: Create enterprise Getting Started guide (installation, 10-min quickstart, migration from community)

### AI Gateway

- [ ] **AIGW-01**: Write AI Gateway concepts page — WHY AI Gateway matters, eBPF-accelerated LLM routing architecture
- [ ] **AIGW-02**: Document KV Cache routing — concepts, cache-aware routing logic, real config from ai_kv_router.go
- [ ] **AIGW-03**: Document vLLM integration — scraper setup, model load balancing from ai_vllm_scraper.go
- [ ] **AIGW-04**: Document AI Security — LlamaFirewall + Presidio integration for AI traffic protection
- [ ] **AIGW-05**: Document PD (Prefill/Decode) disaggregation — cutting-edge LLM serving architecture + config
- [ ] **AIGW-06**: Document KV cache-aware AWS deployment — cloud-native KV cache routing on AWS
- [ ] **AIGW-07**: Document AI API key management — API key config for LLM endpoints
- [ ] **AIGW-08**: Document AI SSE quota management — server-sent events quota control for streaming LLM responses

### Security Gateway

- [ ] **SECG-01**: Document OPA policy enforcement — concepts + loxilb integration config from pkg/opa/
- [ ] **SECG-02**: Document Presidio PII detection/redaction — concepts + deployment config from pkg/presidio/
- [ ] **SECG-03**: Document LlamaFirewall — AI safety, prompt injection protection concepts + setup from pkg/llamafirewall/
- [ ] **SECG-04**: Document Rate limiting — traffic control policies + per-endpoint config from pkg/ratelimit/
- [ ] **SECG-05**: Create Secure Dataplane overview — how loxilb encrypts traffic (IPsec + mTLS + eBPF), conceptual comparison
- [ ] **SECG-06**: Document IPsec — concepts, supported algorithms/versions, tunnel config from ipsec.go
- [ ] **SECG-07**: Document mTLS — concepts, supported TLS versions (TLS 1.3 status), certificate management, cipher suites
- [ ] **SECG-08**: Document Security Gateway deployment scenarios (secgw1-4 patterns)
- [ ] **SECG-09**: Document SYN flood protection — DDoS mitigation at eBPF dataplane level
- [ ] **SECG-10**: Document IP filtering — IP-based access control and filtering rules

### Network Gateway

- [ ] **NETG-01**: Document Egress LB — egress load balancing for outbound traffic
- [ ] **NETG-02**: Document DSR (Direct Server Return) — L2/L3 DSR modes for high-performance LB
- [ ] **NETG-03**: Document NAT64 — IPv6-to-IPv4 translation for dual-stack environments
- [ ] **NETG-04**: Document HTTPS proxy modes — full proxy, SNI routing, prefix routing, persistence
- [ ] **NETG-05**: Document HTTP/2 proxy — HTTP/2 load balancing and prefix routing
- [ ] **NETG-06**: Document SCTP multi-homing — SCTP LB, multi-homing, DSR for telco/5G use cases

### Operations

- [ ] **OPS-01**: Document User management — authentication, authorization, access control from pkg/user/
- [ ] **OPS-02**: Document Monitoring setup — Prometheus metrics, Grafana dashboards for enterprise features

### Reference

- [x] **REF-01**: Create enterprise API reference aligned with swagger.yml
- [x] **REF-02**: Create loxicmd-enterprise CLI reference

## v2 Requirements

Deferred to future milestone. Tracked but not in current roadmap.

### Protocols

- **PROTO-01**: QUIC/HTTP3 support documentation (quiccid, quicgo, picoquic)

### Advanced Features

- **ADV-01**: Plugins system documentation (extensibility framework)
- **ADV-02**: Catalog sync documentation (service catalog management)
- **ADV-03**: DB layer documentation (persistent storage)
- **ADV-04**: L4 Tracing deep-dive (OTLP export, span assembly, ring consumers)

### Community Docs

- **COMM-01**: Reorganize existing 72 community docs into proper hierarchy
- **COMM-02**: Update deployment guides with enterprise context
- **COMM-03**: Korean translations

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full community doc rewrite | Existing use-case docs are mostly accurate; gradual transition |
| Korean translations | English-primary for v1; planned for v2+ |
| Video tutorials | Text documentation only for v1 |
| API auto-generation | Manual docs aligned with swagger.yml; auto-gen in future |
| Interactive demos | Out of scope for ReadTheDocs/MkDocs platform |
| Community doc reorganization | Keep as-is for v1; reorganize in v2 after enterprise features documented |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Pending |
| FOUND-02 | Phase 1 | Pending |
| FOUND-03 | Phase 1 | Pending |
| FOUND-04 | Phase 1 | Pending |
| AIGW-01 | Phase 2 | Pending |
| AIGW-02 | Phase 2 | Pending |
| AIGW-03 | Phase 2 | Pending |
| AIGW-04 | Phase 2 | Pending |
| AIGW-05 | Phase 2 | Pending |
| AIGW-06 | Phase 2 | Pending |
| AIGW-07 | Phase 2 | Pending |
| AIGW-08 | Phase 2 | Pending |
| SECG-01 | Phase 3 | Pending |
| SECG-02 | Phase 3 | Pending |
| SECG-03 | Phase 3 | Pending |
| SECG-04 | Phase 3 | Pending |
| SECG-05 | Phase 3 | Pending |
| SECG-06 | Phase 3 | Pending |
| SECG-07 | Phase 3 | Pending |
| SECG-08 | Phase 3 | Pending |
| SECG-09 | Phase 3 | Pending |
| SECG-10 | Phase 3 | Pending |
| NETG-01 | Phase 4 | Pending |
| NETG-02 | Phase 4 | Pending |
| NETG-03 | Phase 4 | Pending |
| NETG-04 | Phase 4 | Pending |
| NETG-05 | Phase 4 | Pending |
| NETG-06 | Phase 4 | Pending |
| OPS-01 | Phase 4 | Pending |
| OPS-02 | Phase 4 | Pending |
| REF-01 | Phase 5 | Complete |
| REF-02 | Phase 5 | Complete |

**Coverage:**
- v1 requirements: 32 total
- Mapped to phases: 32
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-17*
*Last updated: 2026-03-17 after roadmap creation — all 32 requirements mapped*
