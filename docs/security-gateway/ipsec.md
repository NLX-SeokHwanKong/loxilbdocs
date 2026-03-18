# IPsec Configuration

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is IPsec in loxilb?

IPsec provides **L3 tunnel encryption** between loxilb nodes or external gateways. All traffic between two endpoints is encrypted transparently — applications require no changes, and the encryption is invisible to higher-layer protocols.

loxilb integrates with **strongSwan** for IKE (Internet Key Exchange) negotiation and SA (Security Association) management. loxilb manages the strongSwan configuration files (`/etc/ipsec.conf`, `/etc/ipsec.secrets`) and certificate directories (`/etc/ipsec.d/certs`, `/etc/ipsec.d/private`, `/etc/ipsec.d/cacerts`) through the REST API.

**Authentication modes:**

- **Pre-Shared Key (PSK)** — Shared secret between peers. Simpler setup, suitable for small deployments.
- **X.509 Certificates** — Certificate-based identity. Recommended for production — enables automated rotation and identity verification.

**IKE versions:** Both IKEv1 and IKEv2 are supported. IKEv2 is recommended for new deployments — it has simpler negotiation, built-in NAT traversal, and better security properties.

## Supported Algorithms

### Encryption

| Algorithm | Strength | Recommendation |
|-----------|----------|----------------|
| `aes256` | Strong | **Recommended** for new deployments |
| `aes128` | Good | Acceptable where performance is constrained |
| `3des` | Legacy | Not recommended — use only for interoperability with legacy systems |

### Integrity

| Algorithm | Strength | Recommendation |
|-----------|----------|----------------|
| `sha512` | Strong | **Recommended** for high-security deployments |
| `sha256` | Good | Acceptable for most deployments |
| `sha1` | Legacy | Not recommended — known collision weaknesses |

### Diffie-Hellman Groups

| Group | Strength | Recommendation |
|-------|----------|----------------|
| `modp4096` | Strong | **Recommended** for high-security deployments |
| `modp2048` | Good | Acceptable minimum for production |
| `modp1024` | Legacy | Not recommended — below NIST recommendations |

## REST API Configuration

### Creating a Tunnel

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/tunnels \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "gw1-to-gw2",
    "local_ip": "10.1.0.1",
    "remote_ip": "10.2.0.1",
    "local_subnet": "192.168.1.0/24",
    "remote_subnet": "192.168.2.0/24",
    "auth_method": "psk",
    "psk": "SecretKey123!",
    "local_id": "@gw1.corp.example.com",
    "remote_id": "@gw2.corp.example.com",
    "ike_version": 2,
    "encryption": "aes256",
    "integrity": "sha256",
    "dh_group": "modp2048",
    "ike_lifetime": 86400,
    "esp_encryption": "aes256",
    "esp_integrity": "sha256",
    "esp_lifetime": 3600,
    "tunnel_mode": "tunnel",
    "auto": "start",
    "dpd": {
      "action": "restart",
      "delay": 30,
      "timeout": 120
    }
  }'

# Response (201): Tunnel created
```

### Tunnel Field Reference

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `name` | string | Any unique string | (required) | Unique tunnel identifier |
| `local_ip` | string | IPv4 address | (required) | Local endpoint IP |
| `remote_ip` | string | IPv4 address | (required) | Remote endpoint IP |
| `auth_method` | string | `"psk"`, `"cert"` | (required) | Authentication method |
| `psk` | string | Any string | — | Pre-shared key (when auth_method=psk) |
| `local_id` | string | Identity string | — | Local identity (e.g., `@hostname`) |
| `remote_id` | string | Identity string | — | Remote identity |
| `cert_name` | string | Certificate name | — | Certificate name (when auth_method=cert) |
| `ca_cert_name` | string | CA cert name | — | CA certificate name |
| `ike_version` | int | `1`, `2` | `2` | IKE version |
| `encryption` | string | `"aes128"`, `"aes256"`, `"3des"` | `"aes256"` | IKE phase 1 encryption |
| `integrity` | string | `"sha256"`, `"sha384"`, `"sha512"` | `"sha256"` | IKE phase 1 integrity |
| `dh_group` | string | `"modp1024"`, `"modp2048"`, `"modp4096"` | `"modp2048"` | IKE phase 1 DH group |
| `ike_lifetime` | int | `> 0` (seconds) | `86400` (24h) | IKE SA lifetime |
| `esp_encryption` | string | `"aes128"`, `"aes256"`, `"3des"` | `"aes256"` | ESP encryption |
| `esp_integrity` | string | `"sha256"`, `"sha384"`, `"sha512"` | `"sha256"` | ESP integrity |
| `esp_lifetime` | int | `> 0` (seconds) | `3600` (1h) | ESP SA lifetime |
| `tunnel_mode` | string | `"tunnel"`, `"transport"` | `"tunnel"` | IPsec mode |
| `auto` | string | `"start"`, `"add"`, `"route"` | `"start"` | Auto-initiation mode |

### Removing a Tunnel

```bash
curl -X DELETE http://loxilb:11111/netlox/v1/config/ipsec/tunnels/gw1-to-gw2 \
  -H "Authorization: Bearer <token>"

# Response (200): {"result": "Success"}
```

## Global IPsec Configuration

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "fast_path_enabled": true,
    "hw_offload_enabled": false,
    "anti_replay_enabled": true,
    "sa_lifetime_warn_seconds": 300,
    "mtu": 1400
  }'

# Response (200): {"result": "Success"}
```

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `fast_path_enabled` | bool | `true`, `false` | `true` | Enable fast path for IPsec traffic |
| `hw_offload_enabled` | bool | `true`, `false` | `false` | Enable QAT/DPAA2 hardware crypto offload |
| `anti_replay_enabled` | bool | `true`, `false` | `true` | Enable anti-replay protection |
| `sa_lifetime_warn_seconds` | int | `> 0` (seconds) | `300` | Seconds before SA expiry to warn |
| `mtu` | int | `> 0` (bytes) | `1400` | MTU for IPsec tunnels |

!!! note "MTU consideration"
    IPsec adds overhead to each packet (ESP header, IV, padding, authentication trailer). The default MTU of 1400 bytes accounts for this overhead on standard 1500-byte networks. Adjust if your network path has a non-standard MTU.

## Certificate Management

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/certificates \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "gateway-cert",
    "certificate": "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----"
  }'

# Response (201): Certificate uploaded
```

Certificate files are stored in strongSwan's standard directories:

| Directory | Purpose |
|-----------|---------|
| `/etc/ipsec.d/certs` | Public certificates |
| `/etc/ipsec.d/private` | Private keys |
| `/etc/ipsec.d/cacerts` | CA certificates |

## Dead Peer Detection (DPD)

DPD monitors tunnel health and takes action when the remote peer becomes unreachable:

| Field | Description | Valid Values |
|-------|-------------|-------------|
| `dpd.action` | Action when peer is dead | `"restart"` (reconnect), `"clear"` (remove tunnel), `"hold"` (wait for recovery) |
| `dpd.delay` | Seconds between keepalive checks | `> 0` (e.g., `30`) |
| `dpd.timeout` | Seconds before declaring peer dead | `> 0` (e.g., `120`) |

**Recommendation:** Use `action: "restart"` with `delay: 30` and `timeout: 120` for production tunnels. This provides automatic recovery after network disruptions.

## Verify

Confirm IPsec tunnels are established:

```bash
curl http://loxilb:11111/netlox/v1/config/ipsec/tunnels/all \
  -H "Authorization: Bearer <token>"

# Response (200):
# [
#   {
#     "name": "gw1-to-gw2",
#     "local_ip": "10.1.0.1",
#     "remote_ip": "10.2.0.1",
#     "status": "established",
#     "bytes_in": 1048576,
#     "bytes_out": 2097152
#   }
# ]
```

Check that `status` is `"established"` and traffic counters (`bytes_in`, `bytes_out`) are incrementing.

## Troubleshoot

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Tunnel stuck in "connecting" | PSK mismatch or firewall blocking IKE ports | Verify PSK matches on both sides; ensure ports 500 and 4500 (UDP) are open |
| DPD triggering too frequently | Unstable network path between peers | Check network stability; increase `dpd.delay` and `dpd.timeout` values |
| Certificate authentication failing | Expired certificate or CA trust chain broken | Check cert expiry dates; verify CA certificate is in cacerts directory |

## See Also

- [IPsec API Reference](../reference/api.md#ipsec)
- [Secure Dataplane Overview](secure-dataplane.md) — How IPsec fits in the three-layer security architecture
- [mTLS Configuration](mtls.md) — L7 mutual authentication (complementary to L3 IPsec)
- [Deployment Scenarios](deployment-scenarios.md) — Encrypted Node Mesh deployment pattern
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
