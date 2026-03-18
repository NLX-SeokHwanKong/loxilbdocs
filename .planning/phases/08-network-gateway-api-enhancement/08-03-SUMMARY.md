---
phase: 08-network-gateway-api-enhancement
plan: 03
status: complete
---

## Summary

Rewrote 2 structural Network Gateway pages (overview.md, sctp-multihoming.md) from source-code-annotated guides to REST API-first operator documentation.

## What Changed

- **overview.md**: Stripped 5 mermaid dotted-line Source annotations. Added REST API Config section introducing the unified `POST /netlox/v1/config/loadbalancer` endpoint. Added feature-to-field mapping table linking each feature to its key API fields. Added common POST structure curl example with response JSON. Added comprehensive common fields reference table (13 fields — the master table referenced by all feature pages). Added Verify section with GET endpoint. Updated mermaid diagram to use API field names instead of CLI flags. Removed source-code language from prose. Added API reference links.
- **sctp-multihoming.md**: Stripped 7 Source annotations (prose, admonition, mermaid label, 2 loxicmd comments, HTML comment, inline prose). Converted basic SCTP, DSR variant, and FullNAT variant configurations to curl POST with response JSON (3 curl examples total). Added option detail table (protocol, secondaryIPs, mode). Created new Verify section (was missing entirely) with REST API GET, CLI, and SCTP association checks. Added Troubleshoot section (3 items). Removed Source reference from Monitoring section. Added API reference links.

## Key Files

### key-files.created
- (none — all files were rewrites of existing pages)

### key-files.modified
- docs/network-gateway/overview.md
- docs/network-gateway/sctp-multihoming.md

## Commits
- `docs(08-03): rewrite overview and sctp-multihoming to REST API-first format`

## Self-Check: PASSED
- [x] Zero Source annotations across both files
- [x] overview.md has REST API Config section with unified endpoint introduction
- [x] overview.md has common fields option table (master reference)
- [x] overview.md has Verify section with GET
- [x] sctp-multihoming.md has 3 curl POST examples (basic, DSR, FullNAT)
- [x] sctp-multihoming.md has option detail table
- [x] sctp-multihoming.md has new Verify section (was missing)
- [x] sctp-multihoming.md has new Troubleshoot section
- [x] API reference links on both pages
- [x] mkdocs build --strict passes
