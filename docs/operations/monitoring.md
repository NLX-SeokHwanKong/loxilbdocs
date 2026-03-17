# Monitoring Setup

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## Overview

loxilb-enterprise exposes Prometheus metrics covering all enterprise features — AI Gateway request tracking, OPA policy sync status, HTTPS proxy connections, and PII detection events — alongside the base community metrics for conntrack, flows, and rule counts.

Metrics are exposed at `/netlox/v1/metrics` on port 11111 using the standard Prometheus exposition format. The `--prometheus` CLI flag must be enabled at loxilb startup.

!!! warning "Enable at Startup"
    Prometheus metrics collection must be enabled with the `--prometheus` (or `-p`) flag when starting loxilb. Without this flag, the `/netlox/v1/metrics` endpoint returns `Prometheus option is disabled.` even though port 11111 is reachable.

    Source: `options/options.go:29`, `handler/prometheus.go:34`

## Quick Start

### Step 1: Enable Prometheus in loxilb

```bash
# Source: options/options.go:29
loxilb --prometheus

# Or combined with other flags:
loxilb --prometheus --userservice --databasehost=127.0.0.1 ...
```

### Step 2: Verify Metrics Endpoint

```bash
# Source: handler/prometheus.go:37
curl http://loxilb:11111/netlox/v1/metrics
# Should return Prometheus text format metrics
```

### Step 3: Configure Prometheus Scrape

**Kubernetes deployment:**

```yaml
# Source: docs/loxilb-incluster-grafana.md
scrape_configs:
  - job_name: 'loxilb-enterprise'
    metrics_path: /netlox/v1/metrics
    static_configs:
      - targets:
          - 'loxilb-service.kube-system.svc.cluster.local:11111'
```

**Standalone deployment:**

```yaml
scrape_configs:
  - job_name: 'loxilb-enterprise'
    metrics_path: /netlox/v1/metrics
    static_configs:
      - targets:
          - '<loxilb-host>:11111'
```

## Enterprise Metrics Reference

### AI Gateway Metrics

Source: `api/prometheus/ai_metrics.go`

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `loxilb_ai_requests_total` | Counter | model, tenant, status | Total completed AI gateway requests |
| `loxilb_ai_request_duration_seconds` | Histogram | model, tenant | AI request latency distribution |
| `loxilb_ai_tokens_total` | Counter | model, tenant, direction | Prompt and completion token counts |

### OPA Watcher Metrics

Source: `api/prometheus/opa_metrics.go`

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `loxilb_opa_watcher_syncs_total` | Counter | status | OPA policy sync operations (success/failure) |
| `loxilb_opa_sync_duration_seconds` | Histogram | -- | Time taken for each OPA sync cycle |
| `loxilb_opa_firewall_rules_total` | Gauge | -- | Current number of OPA-managed firewall rules |
| `loxilb_opa_circuit_breaker_state` | Gauge | -- | Circuit breaker state (0=closed/healthy, 1=open/tripped) |

### Parser and PII Metrics

Source: `pkg/loxinet/payload_metrics.go`

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `loxilb_parser_calls_total` | Counter | protocol, status | Parser invocation count |
| `loxilb_parser_duration_seconds` | Histogram | protocol | Parser execution time |
| `loxilb_registry_operations_total` | Counter | operation | Registry operations (register/deregister/get) |
| `loxilb_parser_pii_redactions_total` | Counter | protocol, field_type | PII redaction events by type |
| `loxilb_parser_body_size_bytes` | Histogram | protocol | HTTP body size distribution |
| `loxilb_parser_attributes_extracted_total` | Counter | protocol | Attributes extracted from payloads |

### HTTPS Proxy Metrics

Source: `api/prometheus/sockproxy_metrics.go`

HTTPS proxy metrics track active connections, TLS handshakes, and proxy bytes transferred for all FullProxy mode load balancer rules. These metrics are prefixed with `loxilb_sockproxy_`.

## Base Community Metrics

These metrics are available in both community and enterprise editions:

Source: `api/prometheus/prometheus.go`

| Metric | Description |
|--------|-------------|
| `active_conntrack_count` | Active connection tracking entries |
| `active_flow_count_tcp` | Active TCP flows |
| `active_flow_count_udp` | Active UDP flows |
| `active_flow_count_sctp` | Active SCTP flows |
| `new_flow_count` | New flow creation rate |
| `processed_bytes` | Total bytes processed |
| `processed_tcp_bytes` | TCP bytes processed |
| `total_requests` | Total request count |
| `total_errors` | Total error count |
| `healthy_host_count` | Healthy backend count |
| `lb_rule_count` | Active load balancer rules |
| `total_fw_drops` | Firewall dropped packets |

## Grafana Integration

### Community Dashboard

The community Grafana dashboard covers base metrics and provides a solid starting point for enterprise monitoring. See the [In-Cluster Grafana Setup](../loxilb-incluster-grafana.md) guide for dashboard import instructions.

### Enterprise Metric Queries

Use the following PromQL queries to build custom Grafana panels for enterprise features:

```promql
# AI Gateway: Request rate by model
rate(loxilb_ai_requests_total[5m])

# AI Gateway: P99 latency by model
histogram_quantile(0.99, rate(loxilb_ai_request_duration_seconds_bucket[5m]))

# AI Gateway: Token throughput
rate(loxilb_ai_tokens_total[5m])

# OPA: Sync failure rate
rate(loxilb_opa_watcher_syncs_total{status="failure"}[5m])

# OPA: Circuit breaker state (alert on 1=open)
loxilb_opa_circuit_breaker_state

# PII: Redaction rate by field type
rate(loxilb_parser_pii_redactions_total[5m])

# Overall: Error rate
rate(total_errors[5m]) / rate(total_requests[5m])
```

!!! note "Enterprise Grafana Dashboard"
    A pre-built Grafana dashboard for enterprise metrics is not yet included in the repository. Use the PromQL queries above to create custom panels, or extend the community dashboard with enterprise-specific rows.

## Alerting Recommendations

The following alerts cover critical enterprise monitoring scenarios:

| Alert | Condition | Severity |
|-------|-----------|----------|
| OPA Circuit Breaker Open | `loxilb_opa_circuit_breaker_state == 1` | Critical |
| OPA Sync Failures | `rate(loxilb_opa_watcher_syncs_total{status="failure"}[5m]) > 0` | Warning |
| High AI Latency | `histogram_quantile(0.99, rate(loxilb_ai_request_duration_seconds_bucket[5m])) > 5` | Warning |
| PII Redaction Spike | `rate(loxilb_parser_pii_redactions_total[5m]) > 100` | Info |
| High Error Rate | `rate(total_errors[5m]) / rate(total_requests[5m]) > 0.05` | Critical |
| No Healthy Backends | `healthy_host_count == 0` | Critical |
| High Conntrack Usage | `active_conntrack_count > 100000` | Warning |

### Example Alertmanager Rule

```yaml
groups:
  - name: loxilb-enterprise
    rules:
      - alert: OPACircuitBreakerOpen
        expr: loxilb_opa_circuit_breaker_state == 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "OPA circuit breaker is open"
          description: "The OPA watcher circuit breaker has tripped. OPA policy sync has failed repeatedly. Firewall rules are stale."

      - alert: HighAILatency
        expr: histogram_quantile(0.99, rate(loxilb_ai_request_duration_seconds_bucket[5m])) > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "AI Gateway P99 latency exceeds 5 seconds"
          description: "AI Gateway request latency is high. Check backend LLM service health and model load."
```

## See Also

- [User Management](user-management.md) — Authentication, RBAC, and API key management
- [AI Gateway Overview](../ai-gateway/overview.md) — AI Gateway features producing AI metrics
- [Security Gateway Overview](../security-gateway/overview.md) — Security features producing OPA and PII metrics
