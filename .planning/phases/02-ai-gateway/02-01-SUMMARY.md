---
phase: 02-ai-gateway
plan: 01
subsystem: docs
tags: [ai-gateway, llm-routing, ebpf, kv-cache, mermaid, mkdocs]

requires:
  - phase: 01-foundation
    provides: MkDocs nav structure, enterprise admonition pattern, stub pages
provides:
  - AI Gateway concepts page (overview.md) explaining what/why/how for networking engineers
  - LLM routing architecture page (llm-routing.md) with three-tier routing cascade documentation
  - Mermaid traffic flow diagram and tier-cascade flowchart
  - Foundational concepts referenced by all subsequent AI Gateway pages
affects: [02-02, 02-03, 02-04]

tech-stack:
  added: []
  patterns: [concept-before-config page structure, networking-analogy framing for ML concepts, source-annotation inline references]

key-files:
  created:
    - docs/ai-gateway/overview.md
    - docs/ai-gateway/llm-routing.md
  modified: []

key-decisions:
  - "Used Mermaid sequenceDiagram for traffic flow (clear request/response visualization) and flowchart for tier cascade (decision tree)"
  - "Kept overview conceptual with no config blocks — config examples deferred to dedicated pages per plan structure"
  - "Framed every ML term with networking analogies: KV cache = sticky sessions at GPU level, Tier 1.5 = content-based routing, Tier 2 = least-connections"

patterns-established:
  - "Enterprise admonition at top of every page"
  - "Concept-before-config structure: problem → how loxilb solves it → architecture → config pointers"
  - "Networking-analogy pattern for explaining ML/AI concepts to networking engineers"
  - "Source annotation format: (Source: file.go:line) in prose, # Source: in code blocks"

requirements-completed: [AIGW-01]

duration: 8min
completed: 2026-03-17
---

# Plan 02-01: AI Gateway Concepts & LLM Routing Summary

**AI Gateway overview and LLM routing architecture pages written for networking engineers — with Mermaid diagrams, three-tier routing cascade, and eBPF architecture explanation**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-17
- **Completed:** 2026-03-17
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- AI Gateway overview page explains what/why/how for networking engineers with zero ML background assumed
- LLM routing page documents all three tiers (session stickiness, KV block-hash exact match, GPU queue-depth scoring, CHWBL fallback) with networking analogies
- Both pages include Mermaid diagrams (traffic flow sequence diagram, tier-cascade flowchart)
- FullProxy mode=4 prerequisite documented on both pages with warning admonitions
- LB selection modes table (sel=8/9/10) documented for LLM workloads
- Cross-references to all downstream AI Gateway pages established

## Task Commits

1. **Task 1 + 2: Write overview.md and llm-routing.md** - `49751d5` (feat)

## Files Created/Modified
- `docs/ai-gateway/overview.md` - Full concepts page: what is AI Gateway, eBPF rationale, key capabilities, traffic flow Mermaid diagram, prerequisites, LB selection modes
- `docs/ai-gateway/llm-routing.md` - Full architecture page: LLM routing problem, three-tier routing with networking analogies, model-name routing, CGO bridge pattern, prerequisites

## Decisions Made
- Combined both tasks into a single commit since they are tightly coupled foundational content
- Used sequenceDiagram for traffic flow (shows request/response lifecycle) and flowchart for tier cascade (shows decision tree)
- Kept overview conceptual without config blocks per plan instructions

## Deviations from Plan
None - plan executed as specified.

## Issues Encountered
None - mkdocs build --strict passes clean. Pre-existing community doc warnings (ha-deploy.md, k8s_bgp_policy_crd.md anchor issues) are unrelated.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Overview and routing architecture pages establish the conceptual foundation
- All downstream pages (KV caching, vLLM integration, model LB, advanced features) can now reference back to these concepts
- Cross-reference links to deeper pages are in place (will resolve when those pages are written)

---
*Phase: 02-ai-gateway*
*Completed: 2026-03-17*
