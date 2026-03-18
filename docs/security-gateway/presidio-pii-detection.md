# PII Detection with Presidio

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is Presidio PII Detection?

Microsoft Presidio is an open-source PII (Personally Identifiable Information) detection and anonymization framework. loxilb integrates Presidio as a **gateway-layer PII interceptor** — detecting and optionally redacting sensitive data (names, emails, credit card numbers, SSNs) in LLM prompts before they reach the backend model.

Why at the gateway? PII detection at the gateway layer means **no individual application needs PII scanning logic**. One enforcement point protects all LLM traffic flowing through loxilb, regardless of which application or client originated the request.

## What Presidio Detects

Presidio uses **structural and pattern-based detection** to identify PII entities:

| PII Type | Examples | Detection Method |
|----------|----------|-----------------|
| Person names | "John Smith", "Maria Garcia" | Named Entity Recognition (NER) models |
| Email addresses | "user@example.com" | Pattern matching |
| Phone numbers | "+1-555-0123", "(555) 555-1234" | Pattern matching |
| Credit card numbers | "4111-1111-1111-1111" | Pattern matching + Luhn validation |
| Social Security Numbers | "123-45-6789" | Pattern matching |
| Physical addresses | "123 Main St, City, State 12345" | NER models |

### Presidio vs LlamaFirewall for PII

Presidio and [LlamaFirewall](llamafirewall.md) take different approaches to PII detection. They are **complementary, not competing**:

| Aspect | Presidio | LlamaFirewall PIIDetection |
|--------|----------|---------------------------|
| **Detection method** | Structural — regex patterns, NER models | Semantic — context-based understanding |
| **Strength** | Catches formatted PII (emails, SSNs, credit cards) | Catches contextual PII exposure ("my boss John told me...") |
| **False positives** | Low for structured data | Higher, but catches more subtle leakage |
| **Recommendation** | Enable for all deployments | Enable for defense-in-depth |

For comprehensive protection, **enable both**: Presidio catches structural PII patterns, LlamaFirewall's PIIDetection scanner catches contextual PII exposure that pattern matching cannot detect.

## Architecture

loxilb communicates with Presidio through a REST API for configuration management and gRPC for runtime scanning.

### REST API Configuration

The REST API manages Presidio configuration. The shared memory mechanism is the runtime implementation — the REST API writes configuration that the dataplane reads from shared memory at `/dev/shm/loxilb_presidio_config`.

### gRPC Endpoints

Presidio exposes two gRPC services:

| Service | Default Port | Purpose |
|---------|-------------|---------|
| **Presidio Analyzer** | 50051 | Identifies PII entities in text — returns entity types, positions, and confidence scores |
| **Presidio Anonymizer** | (separate) | Redacts or masks identified PII entities — replaces real data with placeholders |

**Request flow:**

```
Request arrives at AI Gateway
  → sockproxy extracts prompt text
  → Presidio Analyzer identifies PII entities via gRPC
  → Presidio Anonymizer redacts entities (if configured)
  → Clean prompt forwarded to backend LLM
```

!!! info "Port Allocation"
    Presidio Analyzer defaults to port **50051**. [LlamaFirewall](llamafirewall.md) uses port **50052** to avoid conflict. If you run both services, verify port assignments.

## REST API Configuration

### Enable PII Detection

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/pii/enable \
  -H "Authorization: Bearer <token>"

# Response (200): {"result": "Success"}
```

### Configure PII Detection

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/pii/configure \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "presidio_url": "http://presidio-analyzer:5002",
    "score_threshold": 0.7,
    "entities": ["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER", "CREDIT_CARD"],
    "action": "redact"
  }'

# Response (200): {"result": "Success"}
```

### Configuration Field Reference

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `presidio_url` | string | Any HTTP/HTTPS URL | (required) | Presidio analyzer service endpoint |
| `score_threshold` | float | `0.0`–`1.0` | `0.7` | Minimum confidence score to flag PII |
| `entities` | string[] | `"PERSON"`, `"EMAIL_ADDRESS"`, `"PHONE_NUMBER"`, `"CREDIT_CARD"`, etc. | All entities | PII entity types to detect |
| `action` | string | `"redact"`, `"mask"`, `"log"` | `"redact"` | Action when PII is detected |
| `direction` | string | `"request"`, `"response"`, `"both"` | `"request"` | Which traffic direction to scan |

!!! note "Configuration update behavior"
    Configuration updates take effect on the next request cycle, not mid-request. For production configuration changes during high traffic, deploy during a maintenance window or low-traffic period to avoid brief gaps in PII detection.

## Deployment

Presidio runs as **separate containers** — an analyzer and an anonymizer — independent of the loxilb process.

### Container Deployment

```bash
# Run Presidio Analyzer
docker run -d --name presidio-analyzer \
  -p 50051:50051 \
  mcr.microsoft.com/presidio-analyzer:latest

# Run Presidio Anonymizer (optional — only needed for redaction)
docker run -d --name presidio-anonymizer \
  -p 50052:50052 \
  mcr.microsoft.com/presidio-anonymizer:latest
```

### Kubernetes Deployment

In Kubernetes, deploy Presidio as a sidecar or separate service:

**Shared memory requirement:** `/dev/shm` must be accessible from both the loxilb pod and Presidio pods. Options:

- **hostPath volume** — Mount `/dev/shm` from the host (simplest, single-node)
- **emptyDir with medium: Memory** — Kubernetes-native shared memory between containers in the same pod

```yaml
# Example: Shared memory volume in pod spec
volumes:
  - name: shared-memory
    emptyDir:
      medium: Memory
      sizeLimit: 64Mi
```

## Integration with AI Gateway

Presidio operates as part of the AI Gateway's security enforcement stack:

1. **API key validation** — Is the key valid?
2. **Rate limiting** — Is the request within quota?
3. **Presidio PII scan** — Does the prompt contain sensitive data?
4. **LlamaFirewall scan** — Does the prompt contain security threats?
5. **Endpoint selection** — Route to the appropriate backend

Together, Presidio and LlamaFirewall provide **two layers of content protection** before any prompt reaches a backend LLM.

For the full AI Gateway traffic flow, see [AI Gateway Overview](../ai-gateway/overview.md).

## GDPR/CCPA Compliance Context

Gateway-layer PII interception serves as a **technical control for data minimization** — a core principle of both GDPR and CCPA. By detecting and redacting PII at the gateway layer:

- **Sensitive data never reaches LLM backends** — which may log prompts, store them for debugging, or use them for model training.
- **One enforcement point for all traffic** — rather than requiring each application to implement its own PII scanning.
- **Auditable interception** — PII detection events can be logged for compliance reporting.

!!! note "Compliance Advisory"
    Gateway-layer PII detection is a **technical control**, not a complete compliance solution. GDPR and CCPA compliance requires a broader program including data inventory, consent management, data subject rights processes, and legal review. Consult your legal team for full compliance requirements.

## Verify

Confirm PII detection is enabled and configured:

```bash
curl http://loxilb:11111/netlox/v1/config/pii/status \
  -H "Authorization: Bearer <token>"

# Response (200):
# {
#   "enabled": true,
#   "presidio_url": "http://presidio-analyzer:5002",
#   "score_threshold": 0.7,
#   "entities": ["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER", "CREDIT_CARD"],
#   "action": "redact"
# }
```

Check that `enabled` is `true` and configuration values match your intended settings.

## Troubleshoot

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| PII not detected | Entity types not included in `entities` list, or `score_threshold` too high | Verify `entities` list includes target PII types; lower `score_threshold` if needed |
| Presidio connection failed | `presidio_url` incorrect or analyzer service not running | Check `presidio_url` value; verify Presidio analyzer container is running on the expected port |
| High false positive rate | `score_threshold` too low | Increase `score_threshold` (e.g., from 0.5 to 0.7) to reduce false positives |

## See Also

- [PII Detection (Presidio) API Reference](../reference/api.md#pii-detection-presidio)
- [Security Gateway Overview](overview.md) — Fail-mode comparison table, port allocation for all security services
- [LlamaFirewall](llamafirewall.md) — Complementary semantic AI content safety (uses port 50052, Presidio uses 50051)
- [AI Gateway Overview](../ai-gateway/overview.md) — Full traffic flow and architecture
- [Rate Limiting](rate-limiting.md) — Rate limiting configuration
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
