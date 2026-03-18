---
phase: 08-network-gateway-api-enhancement
plan: 02
status: complete
---

## Summary

Rewrote 2 application layer Network Gateway pages (https-proxy.md, http2-proxy.md) from source-code-annotated guides to REST API-first operator documentation.

## What Changed

- **https-proxy.md**: Stripped 7 Source annotations (3 prose lines, 2 loxicmd comments, 2 HTML comments). Converted all 4 mode REST API examples to curl format with response JSON (HTTPS termination, E2E, SNI+prefix, session persistence). Added comprehensive option detail table (security, mode, host, pathPrefix, pathMatchMode, select, sessionHeaderName). Added REST API GET to Verify. Added Troubleshoot section (4 items: mTLS silently ignored, cert paths, SNI mismatch, prefix routing). Mode combination matrix retained. Added API reference links.
- **http2-proxy.md**: Stripped 5 Source annotations (2 prose lines, 1 admonition, 1 loxicmd comment, 1 HTML comment). Converted REST API tab to curl POST with response JSON. Added option detail table (backendProtocol, mode, security). Added REST API GET to Verify. Added Troubleshoot section (3 items: ignored without fullproxy, ALPN failing, gRPC streams). "When to Use Each Protocol" decision table retained. Added API reference links.

## Key Files

### key-files.created
- (none — all files were rewrites of existing pages)

### key-files.modified
- docs/network-gateway/https-proxy.md
- docs/network-gateway/http2-proxy.md

## Commits
- `docs(08-02): rewrite https-proxy, http2-proxy to REST API-first format`

## Self-Check: PASSED
- [x] Zero Source annotations across both files
- [x] https-proxy.md has 4 curl POST examples (one per mode) with response JSON
- [x] http2-proxy.md has curl POST with response JSON
- [x] Option detail tables on both pages
- [x] REST API GET in Verify sections
- [x] Troubleshoot sections on both pages
- [x] API reference links on both pages
- [x] Mode combination matrix retained in https-proxy.md
- [x] "When to Use" decision table retained in http2-proxy.md
- [x] mkdocs build --strict passes
