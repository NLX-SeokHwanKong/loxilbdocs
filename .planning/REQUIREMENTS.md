# Requirements: Practical API Enhancement

**Defined:** 2026-03-18
**Core Value:** Every gateway feature documented with practical REST API examples, option explanations, and request/response flows — operators can configure without reading source code.

## v1.1 Requirements

Requirements for practical API-first documentation across all three gateways.

### AI Gateway Enhancement

- [ ] **AIGW-E01**: Every AI Gateway page has complete REST API examples with request AND response JSON
- [ ] **AIGW-E02**: Every AI Gateway config option has a detail table (field, type, valid values, default, description)
- [ ] **AIGW-E03**: Remove source-code line annotations from all AI Gateway pages
- [ ] **AIGW-E04**: Every AI Gateway page links to its API spec section in reference/api.md
- [ ] **AIGW-E05**: Every AI Gateway page follows "Concept → REST API Config → Verify → Troubleshoot" structure

### Security Gateway Enhancement

- [ ] **SECG-E01**: Every Security Gateway page has complete REST API examples with request AND response JSON
- [ ] **SECG-E02**: Every Security Gateway config option has a detail table (field, type, valid values, default, description)
- [ ] **SECG-E03**: Remove source-code line annotations from all Security Gateway pages
- [ ] **SECG-E04**: Every Security Gateway page links to its API spec section in reference/api.md
- [ ] **SECG-E05**: Every Security Gateway page follows "Concept → REST API Config → Verify → Troubleshoot" structure

### Network Gateway Enhancement

- [ ] **NETG-E01**: Every Network Gateway page has complete REST API examples with request AND response JSON
- [ ] **NETG-E02**: Every Network Gateway config option has a detail table (field, type, valid values, default, description)
- [ ] **NETG-E03**: Remove source-code line annotations from all Network Gateway pages
- [ ] **NETG-E04**: Every Network Gateway page links to its API spec section in reference/api.md
- [ ] **NETG-E05**: Every Network Gateway page follows "Concept → REST API Config → Verify → Troubleshoot" structure

## Out of Scope

| Feature | Reason |
|---------|--------|
| Operations pages (user-management, monitoring) | User requested gateway pages only |
| Community docs enhancement | Separate milestone; different audience |
| New feature documentation | v1.1 is enhancement of existing content only |
| CLI (loxicmd) examples | CLI incomplete for enterprise features; REST API is primary |
| Korean translations | Deferred to future milestone |
| API reference (reference/api.md) rewrite | Already has 84 endpoints; gateway pages link TO it |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AIGW-E01 | Phase 6 | Pending |
| AIGW-E02 | Phase 6 | Pending |
| AIGW-E03 | Phase 6 | Pending |
| AIGW-E04 | Phase 6 | Pending |
| AIGW-E05 | Phase 6 | Pending |
| SECG-E01 | Phase 7 | Pending |
| SECG-E02 | Phase 7 | Pending |
| SECG-E03 | Phase 7 | Pending |
| SECG-E04 | Phase 7 | Pending |
| SECG-E05 | Phase 7 | Pending |
| NETG-E01 | Phase 8 | Pending |
| NETG-E02 | Phase 8 | Pending |
| NETG-E03 | Phase 8 | Pending |
| NETG-E04 | Phase 8 | Pending |
| NETG-E05 | Phase 8 | Pending |

**Coverage:**
- v1.1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-03-18*
*Last updated: 2026-03-18 after roadmap creation*
