---
phase: 08-network-gateway-api-enhancement
plan: 01
status: complete
---

## Summary

Rewrote 3 traffic management Network Gateway pages (egress-lb.md, dsr.md, nat64.md) from source-code-annotated guides to REST API-first operator documentation.

## What Changed

- **egress-lb.md**: Stripped 4 Source annotations (mermaid, loxicmd comment, HTML comment, CRD comment). Converted REST API tab to curl POST with response JSON. Added `egress` option detail table. Added REST API GET to Verify section. Added Troubleshoot section (3 items). Added API reference links.
- **dsr.md**: Stripped 4 Source annotations (mermaid, admonition prose, loxicmd comment, HTML comment). Converted REST API tab to curl POST with response JSON. Added `mode`/`select` option detail table. Added REST API GET to Verify. Added Troubleshoot section (3 items). Added API reference links.
- **nat64.md**: Stripped 4 Source annotations (bash comment, loxicmd comment, HTML comment, inline prose). Converted REST API tab to curl POST with response JSON. Added NAT64 activation option table (documents IPv6 VIP + IPv4 endpoints pattern). Added REST API GET to Verify. Added Troubleshoot section (3 items). Removed inline Source reference from NAT66 note. Added API reference links.

## Key Files

### key-files.created
- (none — all files were rewrites of existing pages)

### key-files.modified
- docs/network-gateway/egress-lb.md
- docs/network-gateway/dsr.md
- docs/network-gateway/nat64.md

## Commits
- `docs(08-01): rewrite egress-lb, dsr, nat64 to REST API-first format`

## Self-Check: PASSED
- [x] Zero Source annotations (grep returns 0 across all 3 files)
- [x] curl POST with response JSON on all 3 pages
- [x] Option detail tables on all 3 pages
- [x] REST API GET in Verify sections
- [x] Troubleshoot sections on all 3 pages
- [x] API reference links (community-api-baseline + SwaggerHub) on all 3 pages
- [x] Concept -> REST API Config -> Verify -> Troubleshoot structure
- [x] mkdocs build --strict passes
