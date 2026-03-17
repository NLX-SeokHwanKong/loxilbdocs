---
phase: 04-network-gateway-and-operations
plan: 01
subsystem: docs
tags: [network-gateway, egress-lb, dsr, nat64, ebpf, load-balancing]

requires:
  - phase: 01-foundation
    provides: MkDocs structure, enterprise admonition pattern, nav hierarchy
provides:
  - Network Gateway overview landing page with architecture diagram and feature table
  - Egress LB documentation with loxicmd, REST API, and Kubernetes CRD tabs
  - DSR documentation covering L2-DSR and L3-DSR with port constraint warning
  - NAT64 documentation with IPv6 prerequisites and kernel requirement note
affects: [04-02, 04-03, 04-04, 05-reference]

tech-stack:
  added: []
  patterns: [network-gateway-feature-page-structure, mermaid-architecture-diagrams]

key-files:
  created:
    - docs/network-gateway/overview.md
    - docs/network-gateway/egress-lb.md
    - docs/network-gateway/dsr.md
    - docs/network-gateway/nat64.md
  modified: []

key-decisions:
  - "Used same enterprise admonition + tabbed config pattern as Phases 2 and 3"
  - "Added 'When to Use DSR' decision table for architect guidance"

patterns-established:
  - "Pattern: Network Gateway pages follow overview -> architecture diagram -> prerequisites -> config tabs -> verification"

requirements-completed: [NETG-01, NETG-02, NETG-03]

duration: 8min
completed: 2026-03-17
---

# Plan 04-01: Network Gateway Overview, Egress LB, DSR, NAT64 Summary

**Network Gateway overview with architecture diagram and three feature pages covering outbound SNAT, L2/L3 direct server return, and IPv6-to-IPv4 translation**

## Performance

- **Duration:** 8 min
- **Tasks:** 4
- **Files modified:** 4

## Accomplishments
- Network Gateway overview landing page with Mermaid architecture diagram showing all six feature modes branching from the unified LB API
- Egress LB page with three configuration tabs (loxicmd, REST API, Kubernetes CRD) covering outbound SNAT through gateway nodes
- DSR page documenting L2-DSR (MAC rewrite) and L3-DSR (IPinIP tunnel) with prominent port constraint warning and backend configuration steps
- NAT64 page explaining eBPF protocol translation with kernel 4.18+ requirement note and dual-stack deployment guidance

## Task Commits

1. **Task 1-4: Write all four pages** - `a2e9c91` (docs)

## Files Created/Modified
- `docs/network-gateway/overview.md` - Landing page with architecture diagram, feature summary table, and navigation to all six feature pages
- `docs/network-gateway/egress-lb.md` - Egress LB with loxicmd, REST API, and K8s CRD tabs
- `docs/network-gateway/dsr.md` - DSR with L2/L3 modes, port constraint warning, backend config
- `docs/network-gateway/nat64.md` - NAT64 with IPv6 sysctl prerequisites and kernel requirement

## Decisions Made
None - followed plan as specified

## Deviations from Plan
None - plan executed as written

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Overview page links to all six feature pages including the three from plan 04-02
- DSR page cross-references SCTP multi-homing page from plan 04-02

---
*Phase: 04-network-gateway-and-operations*
*Completed: 2026-03-17*
