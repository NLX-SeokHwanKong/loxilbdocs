# LlamaFirewall

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is LlamaFirewall?

LlamaFirewall is Meta's open-source AI safety framework that inspects LLM prompts and responses for security threats. loxilb integrates LlamaFirewall as an **inline scanner in the AI Gateway traffic path** — every request passes through LlamaFirewall before reaching the backend LLM, and every response is scanned before being returned to the client.

In the AI Gateway pipeline, LlamaFirewall sits **after API key validation and rate limiting, but before endpoint selection**. This means malicious prompts are blocked before they consume GPU resources, and unsafe responses are caught before reaching the client.

(Source: ai_gateway_dp.go traffic flow, ai_security.go:372)

## Threat Model

Understanding what threats LlamaFirewall protects against is essential before configuring it. The following table maps each threat to its scanner:

| Threat | Scanner | Description |
|--------|---------|-------------|
| **Prompt injection** | PromptGuard | Detects attempts to override system prompts or inject malicious instructions that manipulate LLM behavior |
| **Insecure code generation** | CodeShield | Identifies generated code with known vulnerabilities — SQL injection, XSS, buffer overflows, hardcoded credentials |
| **Credential leakage** | Regex | Detects API keys, passwords, access tokens, and secrets in prompts and responses via configurable regex patterns |
| **Hidden character attacks** | HiddenASCII | Detects invisible Unicode characters (zero-width spaces, RTL overrides) used to smuggle instructions past human review |
| **Agent misalignment** | AgentAlignment | Monitors AI agent actions for deviation from intended behavior — detects when agents attempt unauthorized operations (off by default) |
| **PII exposure** | PIIDetection | Detects personally identifiable information in prompts and responses (off by default — use [Presidio](presidio-pii-detection.md) for dedicated PII detection) |

## Scanner Configuration

**Default enabled:** PromptGuard, CodeShield, Regex, HiddenASCII

**Default disabled:** AgentAlignment, PIIDetection

**Why is PIIDetection off by default?** [Presidio](presidio-pii-detection.md) provides more comprehensive **structural** PII detection (names, emails, credit cards, SSNs) using pattern matching and Named Entity Recognition (NER) models. LlamaFirewall's PIIDetection is **semantic/context-based** — it understands intent rather than patterns. For defense-in-depth, enable both: Presidio catches structural PII patterns, LlamaFirewall catches contextual PII exposure.

## Configuration

```go
// Source: pkg/loxinet/ai_security.go:156-175
LlamaFirewallConfig{
  Enabled:        true,
  ServerURL:      "localhost:50052",  // default, avoid Presidio port 50051
  TimeoutSec:     15,
  FailClosed:     false,             // WARNING: fail-open by default
  BlockThreshold: 0.9,
  CacheEnabled:   true,
  CacheTTLSec:    300,
  Scanners: LlamaFirewallScanners{
    PromptGuard:    true,
    CodeShield:     true,
    Regex:          true,
    HiddenASCII:    true,
    AgentAlignment: false,
    PIIDetection:   false,
  },
}
```

## Fail-Open vs Fail-Closed

!!! danger "Security Critical: Default is Fail-Open"
    By default, `FailClosed: false`. When the LlamaFirewall gRPC service is unreachable (network issue, service crash, timeout), loxilb **allows all traffic through** (`decision=1`, DECISION_ALLOW).

    For security-sensitive deployments, set `FailClosed: true`. This blocks all traffic when LlamaFirewall is unavailable — safer but causes availability impact if the LlamaFirewall service goes down.

    Source: ai_security.go:157 — `FailClosed: false` is the default. When gRPC connection fails, `result.decision = 1`.

**Choosing fail-open vs fail-closed:**

| Mode | Setting | When Traffic Flows | When LlamaFirewall Down | Best For |
|------|---------|-------------------|------------------------|----------|
| **Fail-open** (default) | `FailClosed: false` | Always, unless scan explicitly blocks | Traffic allowed unscanned | Availability-first deployments |
| **Fail-closed** | `FailClosed: true` | Only when scan passes | All traffic blocked | Security-first deployments, compliance requirements |

## Response Processing

When LlamaFirewall scans a request, it returns a `security_scan_result_t` structure:

| Field | Values | Description |
|-------|--------|-------------|
| `decision` | `0` = unspecified, `1` = allow, `2` = block, `3` = HITL | Scan verdict |
| `reason` | string | Human-readable explanation of the verdict |
| `score` | `0.0` to `1.0` | Confidence score |

- **Block threshold:** `0.9` (default). Scores at or above this threshold result in a block decision.
- **HITL (Human-in-the-Loop):** Decision value `3` is intended for future manual review workflows where borderline content is flagged for human review rather than automatically blocked.

(Source: ai_security.go:26-98)

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

2. **Configure loxilb connection** — Set `ServerURL` to the LlamaFirewall address:
    - Same host: `"localhost:50052"`
    - Remote: `"llamafirewall.service.local:50052"`

3. **Verify connectivity** — Check that loxilb can reach the gRPC endpoint. LlamaFirewall logs will show incoming scan requests.

!!! info "Port Allocation"
    LlamaFirewall defaults to port **50052** (not 50051). Port 50051 is reserved for [Presidio](presidio-pii-detection.md). If you run both services, ensure they use different ports.

## Integration with AI Gateway

LlamaFirewall is part of the AI Gateway enforcement pipeline:

```
Client request
  → API key validation (llb_ai_validate_key)
  → Rate limit check (llb_ai_ratelimit_check)
  → LlamaFirewall scan (llb_llamafirewall_scan)    ← HERE
  → Endpoint selection and forwarding
  → Backend vLLM processes request
  → Response returned to client
```

**CGO bridge:** The scan is invoked via `llb_llamafirewall_scan()` in ai_security.go:372. This follows the standard CGO bridge pattern — C sockproxy calls the Go function, which makes a gRPC call to the LlamaFirewall service and returns the decision.

**Caching:** When `CacheEnabled: true` and `CacheTTLSec: 300` (default), scan results for identical prompts are cached for 5 minutes. This significantly reduces latency for repeated queries (e.g., multiple users asking the same question) without re-scanning.

For the full AI Gateway traffic flow, see [AI Gateway Overview](../ai-gateway/overview.md).

## See Also

- [PII Detection with Presidio](presidio-pii-detection.md) — Complementary structural PII detection
- [AI Gateway Overview](../ai-gateway/overview.md) — Full traffic flow diagram
- [Rate Limiting](rate-limiting.md) — Rate limiting configuration
