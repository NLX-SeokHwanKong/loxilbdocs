# Roadmap: loxilb-enterprise Documentation Renewal

## Milestones

- ✅ **v1.0 Documentation Renewal** — Phases 1-5 (shipped 2026-03-18)
- 🚧 **v1.1 Practical API Enhancement** — Phases 6-8 (in progress)

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

### 🚧 v1.1 Practical API Enhancement (In Progress)

**Milestone Goal:** Transform every gateway page from source-code reference to practical REST API guide with full request/response examples, option tables, API spec links, and Concept-API-Verify-Troubleshoot structure.

- [ ] **Phase 6: AI Gateway API Enhancement** - Rewrite 10 AI Gateway pages to REST API-first format
- [ ] **Phase 7: Security Gateway API Enhancement** - Rewrite 12 Security Gateway pages to REST API-first format
- [ ] **Phase 8: Network Gateway API Enhancement** - Rewrite 7 Network Gateway pages to REST API-first format

**Note:** Phases 6, 7, and 8 are independent and can execute in parallel.

## Phase Details

### Phase 6: AI Gateway API Enhancement
**Goal**: Operators can configure every AI Gateway feature using documented REST API examples without reading source code
**Depends on**: Nothing (independent of Phases 7 and 8; builds on shipped v1.0)
**Requirements**: AIGW-E01, AIGW-E02, AIGW-E03, AIGW-E04, AIGW-E05
**Success Criteria** (what must be TRUE):
  1. Every AI Gateway page shows complete REST API request AND response JSON for each configurable feature
  2. Every AI Gateway config option has a detail table with field, type, valid values, default, and description
  3. No source-code line annotations (e.g., `enterprise/pkg/...`) remain on any AI Gateway page
  4. Every AI Gateway page links to its corresponding API spec section in reference/api.md
  5. Every AI Gateway page follows the "Concept -> REST API Config -> Verify -> Troubleshoot" structure
**Plans**: 06-01 (overview + llm-routing), 06-02 (kv-caching + vllm + model-lb + pd-disagg + aws-kv), 06-03 (api-key + sse-quota + config-ref) — all wave 1

### Phase 7: Security Gateway API Enhancement
**Goal**: Operators can configure every Security Gateway feature using documented REST API examples without reading source code
**Depends on**: Nothing (independent of Phases 6 and 8; builds on shipped v1.0)
**Requirements**: SECG-E01, SECG-E02, SECG-E03, SECG-E04, SECG-E05
**Success Criteria** (what must be TRUE):
  1. Every Security Gateway page shows complete REST API request AND response JSON for each configurable feature
  2. Every Security Gateway config option has a detail table with field, type, valid values, default, and description
  3. No source-code line annotations remain on any Security Gateway page
  4. Every Security Gateway page links to its corresponding API spec section in reference/api.md
  5. Every Security Gateway page follows the "Concept -> REST API Config -> Verify -> Troubleshoot" structure
**Plans**: TBD

### Phase 8: Network Gateway API Enhancement
**Goal**: Operators can configure every Network Gateway feature using documented REST API examples without reading source code
**Depends on**: Nothing (independent of Phases 6 and 7; builds on shipped v1.0)
**Requirements**: NETG-E01, NETG-E02, NETG-E03, NETG-E04, NETG-E05
**Success Criteria** (what must be TRUE):
  1. Every Network Gateway page shows complete REST API request AND response JSON for each configurable feature
  2. Every Network Gateway config option has a detail table with field, type, valid values, default, and description
  3. No source-code line annotations remain on any Network Gateway page
  4. Every Network Gateway page links to its corresponding API spec section in reference/api.md
  5. Every Network Gateway page follows the "Concept -> REST API Config -> Verify -> Troubleshoot" structure
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 4/4 | Complete | 2026-03-17 |
| 2. AI Gateway | v1.0 | 4/4 | Complete | 2026-03-17 |
| 3. Security Gateway | v1.0 | 5/5 | Complete | 2026-03-17 |
| 4. Network Gateway & Operations | v1.0 | 4/4 | Complete | 2026-03-17 |
| 5. Reference | v1.0 | 2/2 | Complete | 2026-03-17 |
| 6. AI Gateway API Enhancement | v1.1 | 0/3 | Planned | - |
| 7. Security Gateway API Enhancement | v1.1 | 0/TBD | Not started | - |
| 8. Network Gateway API Enhancement | v1.1 | 0/TBD | Not started | - |
