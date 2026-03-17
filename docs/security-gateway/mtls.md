# mTLS Configuration

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is mTLS in loxilb?

Mutual TLS (mTLS) requires both client and server to present certificates during the TLS handshake. In loxilb, mTLS is configured **per load balancer rule** for HTTPS FullProxy mode — enabling fine-grained authentication control at the service level.

Standard TLS only validates the server's identity (the client verifies the server's certificate). mTLS adds the reverse direction: the server also validates the client's certificate. This provides **mutual authentication** — both sides prove their identity before any data is exchanged.

!!! warning "FullProxy mode required"
    mTLS only works with `security=1` (HTTPS) or `security=2` (E2E HTTPS) and `mode=4` (FullProxy). It has **no effect** in DSR or NAT mode.

    Source: swagger.yml:6360

## Frontend mTLS (Client Certificate Validation)

Frontend mTLS controls how loxilb validates **incoming client certificates**. When a client connects to a load-balanced HTTPS service, loxilb can require and validate the client's certificate.

```json
// Source: common/common_mtls.go:34-56 (MTLSFrontendConfig)
"mtls_frontend": {
  "client_cert_mode": "required",
  "client_ca_path": "/opt/loxilb/cert/client_ca_bundle.crt",
  "require_client_cn": true,
  "client_cn_pattern": "*.corp.example.com"
}
```

### Frontend Field Reference

| Field | Type | Description | Values |
|-------|------|-------------|--------|
| `client_cert_mode` | string | Client certificate requirement | `"disabled"`, `"optional"`, `"required"` |
| `client_ca_path` | string | Path to CA bundle for validating client certs | File path |
| `client_ca_cert_data` | string | Inline CA certificate (alternative to path) | PEM-encoded |
| `require_client_cn` | bool | Enforce Common Name matching | `true` / `false` |
| `client_cn_pattern` | string | Glob pattern for allowed CNs | e.g., `"*.corp.example.com"` |

**Client certificate modes:**

| Mode | Behavior |
|------|----------|
| `disabled` | No client certificate requested |
| `optional` | Client certificate requested but not required — connection proceeds without one |
| `required` | Client **must** present a valid certificate signed by the CA at `client_ca_path` |

## Backend mTLS (Server Certificate Verification)

Backend mTLS controls how loxilb authenticates to **backend servers** and verifies their certificates. When loxilb forwards traffic to a backend, it can present its own certificate and verify the backend's certificate.

```json
// Source: common/common_mtls.go (MTLSBackendConfig)
"mtls_backend": {
  "verify_server_cert": true,
  "backend_ca_path": "/opt/loxilb/cert/backend_ca.crt",
  "client_cert_path": "/opt/loxilb/cert/client.crt",
  "client_key_path": "/opt/loxilb/cert/client.key"
}
```

### Backend Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `verify_server_cert` | bool | Validate backend server certificate |
| `backend_ca_path` | string | CA for verifying backend server certs |
| `client_cert_path` | string | Client certificate loxilb presents to backends |
| `client_key_path` | string | Private key for the client certificate |
| `client_cert_data` | string | Inline client certificate (alternative to path) |
| `client_key_data` | string | Inline private key (alternative to path) |

## TLS Version Support

!!! note "TLS configuration is managed at the OpenSSL layer"
    TLS version and cipher suite configuration is managed at the OpenSSL layer in the C data plane (sockproxy). The Go configuration types (`MTLSFrontendConfig`, `MTLSBackendConfig`) do not expose TLS version fields directly. Contact support for cipher suite customization requirements.

    Source confidence: LOW (C layer implementation)

## Integration with Load Balancer Rules

mTLS fields (`mtls_frontend`, `mtls_backend`) are part of the load balancer service rule. They are applied when creating or updating a load balancer service:

```bash
# Apply via load balancer rule API
PUT /netlox/v1/config/loadbalancer/{name}
```

Source: `pkg/loxinet/rules.go:338, 877, 2141`

### Example: Full mTLS Load Balancer Rule

```json
{
  "name": "secure-api",
  "host": "api.corp.example.com",
  "port": 443,
  "protocol": "https",
  "mode": 4,
  "security": 1,
  "mtls_frontend": {
    "client_cert_mode": "required",
    "client_ca_path": "/opt/loxilb/cert/client_ca.crt",
    "require_client_cn": true,
    "client_cn_pattern": "*.internal.corp.example.com"
  },
  "mtls_backend": {
    "verify_server_cert": true,
    "backend_ca_path": "/opt/loxilb/cert/backend_ca.crt",
    "client_cert_path": "/opt/loxilb/cert/lb_client.crt",
    "client_key_path": "/opt/loxilb/cert/lb_client.key"
  },
  "endpoints": [
    {"ep_address": "10.0.1.10", "ep_port": 8443}
  ]
}
```

This configuration:

1. **Frontend:** Requires all clients to present a certificate signed by `client_ca.crt` with a CN matching `*.internal.corp.example.com`
2. **Backend:** Verifies backend server certificates against `backend_ca.crt` and presents `lb_client.crt` as loxilb's identity to backends

## See Also

- [Secure Dataplane Overview](secure-dataplane.md) — How mTLS fits in the three-layer security architecture
- [IPsec Configuration](ipsec.md) — L3 tunnel encryption (complementary to L7 mTLS)
- [Deployment Scenarios](deployment-scenarios.md) — Full Enterprise Security Gateway deployment pattern
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
