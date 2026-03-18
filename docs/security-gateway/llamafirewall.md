# LlamaFirewall

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is LlamaFirewall?

LlamaFirewall is Meta's open-source AI safety framework that inspects LLM prompts and responses for security threats. loxilb integrates LlamaFirewall as an **inline scanner in the AI Gateway traffic path** — every request passes through LlamaFirewall before reaching the backend LLM, and every response is scanned before being returned to the client.

In the AI Gateway pipeline, LlamaFirewall sits **after API key validation and rate limiting, but before endpoint selection**. This means malicious prompts are blocked before they consume GPU resources, and unsafe responses are caught before reaching the client.

## Threat Model

Understanding what threats LlamaFirewall protects against is essential before configuring it. The following table maps each threat to its scanner:

| Threat | Scanner | Description |
|--------|---------|-------------|
| **Prompt injection** | prompt-injection | Detects attempts to override system prompts or inject malicious instructions that manipulate LLM behavior |
| **Insecure code generation** | code-shield | Identifies generated code with known vulnerabilities — SQL injection, XSS, buffer overflows, hardcoded credentials |
| **Credential leakage** | regex | Detects API keys, passwords, access tokens, and secrets in prompts and responses via configurable regex patterns |
| **Hidden character attacks** | hidden-ascii | Detects invisible Unicode characters (zero-width spaces, RTL overrides) used to smuggle instructions past human review |
| **Agent misalignment** | agent-alignment | Monitors AI agent actions for deviation from intended behavior — detects when agents attempt unauthorized operations (off by default) |
| **PII exposure** | pii-detection | Detects personally identifiable information in prompts and responses (off by default — use [Presidio](presidio-pii-detection.md) for dedicated PII detection) |

## Scanner Configuration

**Default enabled:** prompt-injection, code-shield, regex, hidden-ascii

**Default disabled:** agent-alignment, pii-detection

**Why is pii-detection off by default?** [Presidio](presidio-pii-detection.md) provides more comprehensive **structural** PII detection (names, emails, credit cards, SSNs) using pattern matching and Named Entity Recognition (NER) models. LlamaFirewall's pii-detection is **semantic/context-based** — it understands intent rather than patterns. For defense-in-depth, enable both: Presidio catches structural PII patterns, LlamaFirewall catches contextual PII exposure.

## REST API Configuration

### Enable LlamaFirewall

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/llamafirewall/enable \
  -H "Authorization: Bearer <token>"

# Response (200): {"result": "Success"}
```

### Configure Scanners

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/llamafirewall/scanners \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "scanners": [
      {"name": "prompt-injection", "enabled": true, "threshold": 0.8},
      {"name": "content-filter", "enabled": true, "categories": ["violence", "hate"]},
      {"name": "code-shield", "enabled": true},
      {"name": "regex", "enabled": true},
      {"name": "hidden-ascii", "enabled": true}
    ]
  }'

# Response (200): {"result": "Success"}
```

### Scanner Field Reference

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `name` | string | Scanner name (see Threat Model table) | (required) | Scanner identifier |
| `enabled` | bool | `true`, `false` | varies by scanner | Whether the scanner is active |
| `threshold` | float | `0.0`–`1.0` | `0.9` | Confidence score threshold for blocking |
| `fail_action` | string | `"block"`, `"allow"` | `"allow"` | Action when scanner encounters an error |

## Fail-Open vs Fail-Closed

!!! danger "Security Critical: Default is Fail-Open"
    By default, when the LlamaFirewall gRPC service is unreachable (network issue, service crash, timeout), loxilb **allows all traffic through**.

    For security-sensitive deployments, configure fail-closed behavior. This blocks all traffic when LlamaFirewall is unavailable — safer but causes availability impact if the LlamaFirewall service goes down.

**Choosing fail-open vs fail-closed:**

| Mode | When Traffic Flows | When LlamaFirewall Down | Best For |
|------|-------------------|------------------------|----------|
| **Fail-open** (default) | Always, unless scan explicitly blocks | Traffic allowed unscanned | Availability-first deployments |
| **Fail-closed** | Only when scan passes | All traffic blocked | Security-first deployments, compliance requirements |

## Response Processing

When LlamaFirewall scans a request, it returns a scan result:

| Field | Values | Description |
|-------|--------|-------------|
| `decision` | `0` = unspecified, `1` = allow, `2` = block, `3` = HITL | Scan verdict |
| `reason` | string | Human-readable explanation of the verdict |
| `score` | `0.0` to `1.0` | Confidence score |

- **Block threshold:** `0.9` (default). Scores at or above this threshold result in a block decision.
- **HITL (Human-in-the-Loop):** Decision value `3` is intended for future manual review workflows where borderline content is flagged for human review rather than automatically blocked.

## Deployment

LlamaFirewall runs as a **separate gRPC service** — it is not embedded in the loxilb process. This allows independent scaling and updates.

**Setup steps:**

1. **Run LlamaFirewall service** — Pull the LlamaFirewall container and start the gRPC server:

    ```bash
    # Example: Run LlamaFirewall on port 50052
    docker run -d --name llamafirewall \
      -p 50052:50052 \
      meta-llama/llamafirewall:latest
    ```

2. **Configure loxilb connection** — Set the server URL to the LlamaFirewall address:
    - Same host: `"localhost:50052"`
    - Remote: `"llamafirewall.service.local:50052"`

3. **Verify connectivity** — Check that loxilb can reach the gRPC endpoint. LlamaFirewall logs will show incoming scan requests.

!!! info "Port Allocation"
    LlamaFirewall defaults to port **50052** (not 50051). Port 50051 is reserved for [Presidio](presidio-pii-detection.md). If you run both services, ensure they use different ports.

## Integration with AI Gateway

LlamaFirewall is part of the AI Gateway enforcement pipeline:

```
Client request
  → API key validation
  → Rate limit check
  → LlamaFirewall scan    ← HERE
  → Endpoint selection and forwarding
  → Backend vLLM processes request
  → Response returned to client
```

**Caching:** When caching is enabled, scan results for identical prompts are cached for 5 minutes. This significantly reduces latency for repeated queries (e.g., multiple users asking the same question) without re-scanning.

For the full AI Gateway traffic flow, see [AI Gateway Overview](../ai-gateway/overview.md).

## Verify

Confirm LlamaFirewall is enabled and scanners are active:

```bash
curl http://loxilb:11111/netlox/v1/config/llamafirewall/status \
  -H "Authorization: Bearer <token>"

# Response (200):
# {
#   "enabled": true,
#   "scanners": [
#     {"name": "prompt-injection", "enabled": true, "threshold": 0.8},
#     {"name": "content-filter", "enabled": true}
#   ],
#   "health": "healthy"
# }
```

Check that `enabled` is `true`, expected scanners are listed, and `health` is `"healthy"`.

You can also check scanning statistics:

```bash
curl http://loxilb:11111/netlox/v1/config/llamafirewall/stats \
  -H "Authorization: Bearer <token>"

# Response (200):
# {
#   "total_scanned": 15420,
#   "blocked": 23,
#   "passed": 15397,
#   "by_scanner": {
#     "prompt-injection": {"scanned": 15420, "blocked": 12},
#     "content-filter": {"scanned": 15420, "blocked": 11}
#   }
# }
```

## Troubleshoot

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Scanners not detecting threats | Scanner `enabled` is `false` or `threshold` too high | Verify scanner configuration via `GET /config/llamafirewall/status`; lower `threshold` if needed |
| High latency from scanning | Too many scanners enabled or large prompt payloads | Disable unused scanners; check LlamaFirewall service resource allocation |
| LlamaFirewall health "unhealthy" | gRPC service not reachable or crashed | Check LlamaFirewall container status; verify network connectivity to port 50052 |

## See Also

- [LlamaFirewall API Reference](../reference/api.md#llamafirewall)
- [Security Gateway Overview](overview.md) — Fail-mode comparison table showing LlamaFirewall fail-open vs OPA fail-closed defaults. See also the [port allocation table](overview.md#port-allocation) — LlamaFirewall uses port 50052, Presidio uses port 50051.
- [PII Detection with Presidio](presidio-pii-detection.md) — Complementary structural PII detection. Presidio catches formatted PII (emails, SSNs), LlamaFirewall catches contextual PII exposure.
- [AI Gateway Overview](../ai-gateway/overview.md) — Full traffic flow diagram showing LlamaFirewall position in the enforcement pipeline
- [Rate Limiting](rate-limiting.md) — Rate limiting configuration
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
