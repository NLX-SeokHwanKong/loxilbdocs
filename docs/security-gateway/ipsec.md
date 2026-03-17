# IPsec Configuration

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is IPsec in loxilb?

IPsec provides **L3 tunnel encryption** between loxilb nodes or external gateways. All traffic between two endpoints is encrypted transparently — applications require no changes, and the encryption is invisible to higher-layer protocols.

loxilb integrates with **strongSwan** for IKE (Internet Key Exchange) negotiation and SA (Security Association) management. loxilb manages the strongSwan configuration files (`/etc/ipsec.conf`, `/etc/ipsec.secrets`) and certificate directories (`/etc/ipsec.d/certs`, `/etc/ipsec.d/private`, `/etc/ipsec.d/cacerts`) through the REST API.

Source: `ipsec.go` — IPsecH struct

**Authentication modes:**

- **Pre-Shared Key (PSK)** — Shared secret between peers. Simpler setup, suitable for small deployments.
- **X.509 Certificates** — Certificate-based identity. Recommended for production — enables automated rotation and identity verification.

**IKE versions:** Both IKEv1 and IKEv2 are supported. IKEv2 is recommended for new deployments — it has simpler negotiation, built-in NAT traversal, and better security properties.

## Supported Algorithms

Source: `ipsec.go:143-148` — SupportedAlgorithms

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

## Tunnel Configuration

### Creating a Tunnel

```json
// Source: common/common.go:1602-1632 (IPsecTunnelMod)
POST /config/ipsec/tunnels
{
  "name": "gw1-to-gw2",
  "localIp": "10.1.0.1",
  "remoteIp": "10.2.0.1",
  "authMode": "psk",
  "psk": "SecretKey123!",
  "localId": "@gw1.corp.example.com",
  "remoteId": "@gw2.corp.example.com",
  "ikeVersion": "ikev2",
  "ikeEncryption": "aes256",
  "ikeIntegrity": "sha256",
  "ikeDhGroup": "modp2048",
  "ikeLifetime": 86400,
  "espEncryption": "aes256",
  "espIntegrity": "sha256",
  "espLifetime": 3600,
  "tunnelMode": "tunnel",
  "auto": "start",
  "dpd": {
    "action": "restart",
    "delay": 30,
    "timeout": 120
  }
}
```

### Tunnel Field Reference

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `name` | string | Unique tunnel identifier | (required) |
| `localIp` | string | Local endpoint IP | (required) |
| `remoteIp` | string | Remote endpoint IP | (required) |
| `authMode` | string | `"psk"` or `"cert"` | (required) |
| `psk` | string | Pre-shared key (when authMode=psk) | — |
| `localId` | string | Local identity (e.g., `@hostname`) | — |
| `remoteId` | string | Remote identity | — |
| `certName` | string | Certificate name (when authMode=cert) | — |
| `caCertName` | string | CA certificate name | — |
| `ikeVersion` | string | `"ikev1"` or `"ikev2"` | `"ikev2"` |
| `ikeEncryption` | string | IKE phase 1 encryption | `"aes256"` |
| `ikeIntegrity` | string | IKE phase 1 integrity | `"sha256"` |
| `ikeDhGroup` | string | IKE phase 1 DH group | `"modp2048"` |
| `ikeLifetime` | int | IKE SA lifetime in seconds | `86400` (24h) |
| `espEncryption` | string | ESP encryption | `"aes256"` |
| `espIntegrity` | string | ESP integrity | `"sha256"` |
| `espDhGroup` | string | ESP PFS DH group | — |
| `espLifetime` | int | ESP SA lifetime in seconds | `3600` (1h) |
| `mark` | int | IPsec mark for policy routing | — |
| `tunnelMode` | string | `"tunnel"` or `"transport"` | `"tunnel"` |
| `auto` | string | `"start"` (initiate), `"add"` (wait), `"route"` (on-demand) | `"start"` |

### Removing a Tunnel

```bash
DELETE /config/ipsec/tunnels
# Body: { "name": "gw1-to-gw2" }
```

## Global IPsec Configuration

```json
// Source: common/common.go:1563-1600 (IPsecConfig)
POST /config/ipsec
{
  "fastPathEnabled": true,
  "hwOffloadEnabled": false,
  "antiReplayEnabled": true,
  "saLifetimeWarnSeconds": 300,
  "mtu": 1400
}
```

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `fastPathEnabled` | bool | Enable fast path for IPsec traffic | `true` |
| `hwOffloadEnabled` | bool | Enable QAT/DPAA2 hardware crypto offload | `false` |
| `antiReplayEnabled` | bool | Enable anti-replay protection | `true` |
| `saLifetimeWarnSeconds` | int | Seconds before SA expiry to warn | `300` |
| `mtu` | int | MTU for IPsec tunnels | `1400` |

!!! note "MTU consideration"
    IPsec adds overhead to each packet (ESP header, IV, padding, authentication trailer). The default MTU of 1400 bytes accounts for this overhead on standard 1500-byte networks. Adjust if your network path has a non-standard MTU.

## Certificate Management

API: `POST /config/ipsec/certificates` and `DELETE /config/ipsec/certificates`

Certificate files are stored in strongSwan's standard directories:

| Directory | Purpose |
|-----------|---------|
| `/etc/ipsec.d/certs` | Public certificates |
| `/etc/ipsec.d/private` | Private keys |
| `/etc/ipsec.d/cacerts` | CA certificates |

## Dead Peer Detection (DPD)

DPD monitors tunnel health and takes action when the remote peer becomes unreachable:

| Field | Description | Values |
|-------|-------------|--------|
| `dpd.action` | Action when peer is dead | `"restart"` (reconnect), `"clear"` (remove tunnel), `"hold"` (wait for recovery) |
| `dpd.delay` | Seconds between keepalive checks | e.g., `30` |
| `dpd.timeout` | Seconds before declaring peer dead | e.g., `120` |

**Recommendation:** Use `action: "restart"` with `delay: 30` and `timeout: 120` for production tunnels. This provides automatic recovery after network disruptions.

## See Also

- [Secure Dataplane Overview](secure-dataplane.md) — How IPsec fits in the three-layer security architecture
- [mTLS Configuration](mtls.md) — L7 mutual authentication (complementary to L3 IPsec)
- [Deployment Scenarios](deployment-scenarios.md) — Encrypted Node Mesh deployment pattern
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
