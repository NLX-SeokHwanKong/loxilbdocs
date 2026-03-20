# IPsec Configuration

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## What is IPsec in loxilb?

IPsec provides **L3 tunnel encryption** between loxilb nodes or external gateways. All traffic between two endpoints is encrypted transparently — applications require no changes, and the encryption is invisible to higher-layer protocols.

loxilb integrates with **strongSwan** for IKE (Internet Key Exchange) negotiation and SA (Security Association) management. loxilb manages the strongSwan configuration files (`/etc/ipsec.conf`, `/etc/ipsec.secrets`) and certificate directories (`/etc/ipsec.d/certs`, `/etc/ipsec.d/private`, `/etc/ipsec.d/cacerts`) through the REST API.

**Authentication modes:**

- **Pre-Shared Key (PSK)** — Shared secret between peers. Simpler setup, suitable for small deployments and dev/test.
- **X.509 Certificates** — Certificate-based identity. Recommended for production — enables automated rotation and identity verification.

## IPsec Tunnel Architecture

The following diagram shows the IPsec tunnel establishment and data plane encryption path:

```mermaid
flowchart TD
    subgraph Node1["loxilb Node 1 (10.1.0.1)"]
        A[Application Traffic] --> B[loxilb IPsec Manager]
        B --> C{Fast Path Enabled?}
        C -->|Yes| D[eBPF Fast Path<br/>SA lookup + encrypt]
        C -->|No| E[Kernel XFRM<br/>Standard IPsec]
        D --> F[ESP Encapsulated<br/>Packet]
        E --> F
    end

    subgraph IKE["IKE Negotiation (Control Plane)"]
        G[strongSwan IKE Daemon]
        H[Certificate Store<br/>/etc/ipsec.d/]
        G <--> H
        G <-->|IKE Phase 1: SA negotiation<br/>IKE Phase 2: ESP SA setup| I[strongSwan IKE Daemon]
    end

    subgraph Node2["loxilb Node 2 (10.2.0.1)"]
        J[ESP Decapsulated<br/>Packet]
        K{Fast Path Enabled?}
        J --> K
        K -->|Yes| L[eBPF Fast Path<br/>SA lookup + decrypt]
        K -->|No| M[Kernel XFRM<br/>Standard IPsec]
        L --> N[Application Traffic]
        M --> N
    end

    F -->|"Encrypted ESP tunnel<br/>UDP 500/4500"| J

    B -.->|"API: tunnel config"| G
    I -.->|"API: tunnel config"| O[loxilb IPsec Manager]

    style F fill:#339af0,color:#fff
    style J fill:#339af0,color:#fff
```

### IKE Negotiation Flow

```mermaid
sequenceDiagram
    participant API as REST API
    participant Mgr as IPsec Manager
    participant SW as strongSwan
    participant Remote as Remote Peer

    API->>Mgr: POST /config/ipsec/tunnels
    Mgr->>Mgr: Write /etc/ipsec.conf<br/>Write /etc/ipsec.secrets
    Mgr->>SW: Reload configuration

    alt PSK Authentication
        SW->>Remote: IKE_SA_INIT (proposals)
        Remote-->>SW: IKE_SA_INIT response
        SW->>Remote: IKE_AUTH (PSK proof)
        Remote-->>SW: IKE_AUTH response
    else Certificate Authentication
        Mgr->>Mgr: Read cert from /etc/ipsec.d/certs/
        SW->>Remote: IKE_SA_INIT (proposals)
        Remote-->>SW: IKE_SA_INIT response
        SW->>Remote: IKE_AUTH (certificate + signature)
        Remote-->>SW: IKE_AUTH (certificate + signature)
    end

    Note over SW,Remote: Child SA established (ESP)
    SW-->>Mgr: SA established notification
    Mgr-->>API: Tunnel state: "up"

    loop Every espLifetime seconds
        SW->>Remote: CREATE_CHILD_SA (rekey)
        Remote-->>SW: CREATE_CHILD_SA response
        Note over SW,Remote: New ESP SA replaces old
    end

    loop Every dpd.delay seconds
        SW->>Remote: DPD keepalive
        alt Peer responds
            Remote-->>SW: DPD response
        else No response within dpd.timeout
            SW->>SW: dpd.action (restart/clear/hold)
        end
    end
```

## Deep Internals

### strongSwan Integration

loxilb manages strongSwan through configuration file generation and reload:

1. **Tunnel creation** (`POST /config/ipsec/tunnels`):
   - Generates a `conn` section in `/etc/ipsec.conf` with the tunnel parameters
   - Writes authentication credentials to `/etc/ipsec.secrets` (PSK or key path)
   - Triggers strongSwan configuration reload

2. **Certificate management** (`POST /config/ipsec/certificates`):
   - Stores certificates in `/etc/ipsec.d/certs/` (public certs)
   - Stores private keys in `/etc/ipsec.d/private/`
   - CA certificates go to `/etc/ipsec.d/cacerts/`

3. **SA lifecycle**:
   - IKE SA is negotiated with `ikeLifetime` (default: 28800s = 8h)
   - ESP SA is negotiated with `espLifetime` (default: 3600s = 1h)
   - Automatic rekeying occurs before SA expiry when `rekey: true` (default)
   - Warning logged `saLifetimeWarnSeconds` (default: 300s) before expiry

### Fast-Path eBPF Bypass

When `fastPathEnabled: true` (default), established IPsec SAs use the eBPF fast path instead of the kernel's standard XFRM framework:

- **SA lookup**: eBPF program performs SA lookup using SPI (Security Parameter Index) from the ESP header
- **Encryption/Decryption**: Crypto operations use the same algorithms but bypass kernel XFRM overhead
- **Performance**: Reduces per-packet latency by avoiding multiple kernel context switches

### Hardware Crypto Offload

When `hwOffloadEnabled: true`, crypto operations are offloaded to hardware accelerators:

| Offload Type | Hardware | Description |
|-------------|----------|-------------|
| `qat` | Intel QAT | Intel QuickAssist Technology crypto accelerator |
| `dpaa2` | NXP DPAA2 | NXP Data Path Acceleration Architecture |
| `inline` | NIC inline | Network card with inline IPsec offload |
| `none` | CPU | Software crypto (default) |

Hardware availability is reported via `GET /config/ipsec` in the `hwCapabilities` field.

### Sequence Number Overflow

IPsec ESP uses 32-bit or 64-bit (ESN) sequence numbers. The `seqOverflowAction` field controls behavior when sequence numbers wrap:

| Action | Behavior |
|--------|----------|
| `rekey` | Trigger immediate SA rekeying (recommended) |
| `drop` | Drop packets (prevents replay attacks but disrupts traffic) |
| `continue` | Continue with wrapped sequence (NOT recommended — replay risk) |

## REST API Configuration

### Global IPsec Configuration

```bash
# Get current configuration
curl http://loxilb:11111/netlox/v1/config/ipsec \
  -H "Authorization: Bearer <token>"

# Update configuration
curl -X PUT http://loxilb:11111/netlox/v1/config/ipsec \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "fastPathEnabled": true,
    "hwOffloadEnabled": false,
    "hwOffloadType": "none",
    "antiReplayEnabled": true,
    "saLifetimeWarnSeconds": 300,
    "seqOverflowAction": "rekey",
    "mtu": 1400
  }'
```

### Global Config Field Reference

Verified against `IPsecConfigMod` in swagger.yml:

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `fastPathEnabled` | boolean | `true`, `false` | `true` | Enable eBPF fast-path bypass for established SAs |
| `hwOffloadEnabled` | boolean | `true`, `false` | `false` | Enable hardware crypto offload |
| `hwOffloadType` | string | `"none"`, `"qat"`, `"dpaa2"`, `"inline"` | `"none"` | Hardware offload type |
| `antiReplayEnabled` | boolean | `true`, `false` | `true` | Enable anti-replay protection |
| `saLifetimeWarnSeconds` | integer (uint32) | `> 0` | `300` | Seconds before SA expiry to warn |
| `seqOverflowAction` | string | `"rekey"`, `"drop"`, `"continue"` | `"rekey"` | Action on sequence number overflow |
| `mtu` | integer (uint16) | `> 0` | `1400` | MTU for IPsec tunnels |

### Creating a Tunnel

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/tunnels \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "gw1-to-gw2",
    "localIp": "10.1.0.1",
    "remoteIp": "10.2.0.1",
    "authMode": "psk",
    "psk": "SecretKey123!",
    "localId": "@gw1.corp.example.com",
    "remoteId": "@gw2.corp.example.com",
    "ikeVersion": "ikev2",
    "ikeEncryption": "aes256-sha256-modp2048",
    "ikeIntegrity": "sha256",
    "ikeDhGroup": "modp2048",
    "ikeLifetime": 28800,
    "espEncryption": "aes256-sha256",
    "espIntegrity": "sha256",
    "espDhGroup": "modp2048",
    "espLifetime": 3600,
    "mark": 100,
    "tunnelMode": "tunnel",
    "installPolicy": true,
    "rekey": true,
    "auto": "start",
    "selector": {
      "srcCidr": "192.168.1.0/24",
      "dstCidr": "192.168.2.0/24"
    },
    "dpd": {
      "action": "restart",
      "delay": 30,
      "timeout": 150
    }
  }'

# Response (201): Tunnel created
```

### Tunnel Field Reference

Verified against `IPsecTunnelMod` in swagger.yml:

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `name` | string | Any unique string | (required) | Tunnel identifier |
| `localIp` | string | IPv4 address | (required) | Local endpoint IP |
| `remoteIp` | string | IPv4 address | (required) | Remote endpoint IP |
| `authMode` | string | `"psk"`, `"cert"` | (required) | Authentication mode |
| `psk` | string | Any string | — | Pre-shared key (required for PSK mode) |
| `localId` | string | Identity string | — | IKE local identifier |
| `remoteId` | string | Identity string | — | IKE remote identifier |
| `certName` | string | Certificate name | — | Certificate name (required for cert mode) |
| `caCertName` | string | CA cert name | — | CA certificate name (required for cert mode) |
| `ikeVersion` | string | `"ikev1"`, `"ikev2"` | `"ikev2"` | IKE version |
| `ikeEncryption` | string | Algorithm string | `"aes256-sha256-modp2048"` | IKE encryption algorithm |
| `ikeIntegrity` | string | Algorithm string | `"sha256"` | IKE integrity algorithm |
| `ikeDhGroup` | string | DH group name | `"modp2048"` | IKE Diffie-Hellman group |
| `ikeLifetime` | integer (uint32) | seconds | `28800` (8h) | IKE SA lifetime |
| `espEncryption` | string | Algorithm string | `"aes256-sha256"` | ESP encryption algorithm |
| `espIntegrity` | string | Algorithm string | `"sha256"` | ESP integrity algorithm |
| `espDhGroup` | string | DH group name | `"modp2048"` | ESP PFS DH group |
| `espLifetime` | integer (uint32) | seconds | `3600` (1h) | ESP SA lifetime |
| `mark` | integer (uint32) | `0`–`4294967295` | `100` | Netfilter mark for VTI routing (0 = no mark) |
| `tunnelMode` | string | `"tunnel"`, `"transport"` | `"tunnel"` | IPsec mode |
| `installPolicy` | boolean | `true`, `false` | `true` | Auto-install XFRM policies |
| `compress` | boolean | `true`, `false` | `false` | Enable IP compression |
| `mobike` | boolean | `true`, `false` | `false` | Enable MOBIKE (IKEv2 mobility) |
| `rekey` | boolean | `true`, `false` | `true` | Enable automatic rekeying |
| `reauth` | boolean | `true`, `false` | `false` | Re-authenticate on rekey |
| `auto` | string | `"start"`, `"add"`, `"route"` | `"start"` | Connection startup mode |

### Tunnel Selector (Traffic Matching)

Verified against `IPsecSelector` in swagger.yml:

| Field | Type | Description |
|-------|------|-------------|
| `srcCidr` | string | Source CIDR (e.g., `"10.0.0.0/24"`) |
| `dstCidr` | string | Destination CIDR (e.g., `"10.1.0.0/24"`) |
| `protocol` | integer (uint8) | IP protocol (132 for SCTP, 0 for any) |
| `srcPort` | integer (uint16) | Source port (0 for any) |
| `dstPort` | integer (uint16) | Destination port (0 for any) |

### Dead Peer Detection (DPD)

Verified against `IPsecDPD` in swagger.yml:

| Field | Type | Valid Values | Default | Description |
|-------|------|-------------|---------|-------------|
| `action` | string | `"restart"`, `"clear"`, `"hold"` | `"restart"` | Action when peer is dead |
| `delay` | integer (uint32) | seconds | `30` | Seconds between DPD checks |
| `timeout` | integer (uint32) | seconds | `150` | DPD response timeout |

### Auto Startup Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `start` | Immediately initiate IKE negotiation | Initiator/client — always-on tunnels |
| `add` | Load config but wait for remote initiation | Responder/server — accept incoming tunnels |
| `route` | Install route, negotiate on first matching traffic | On-demand tunnels — reduce IKE overhead |

### Listing Tunnels

```bash
curl http://loxilb:11111/netlox/v1/config/ipsec/tunnels/all \
  -H "Authorization: Bearer <token>"
```

Tunnel response includes operational fields (verified against `IPsecTunnel`):

| Field | Type | Description |
|-------|------|-------------|
| `state` | string | `"down"`, `"connecting"`, `"up"` |
| `installedAt` | string (datetime) | When tunnel was created |
| `bytesIn` / `bytesOut` | integer (uint64) | Traffic counters |
| `packetsIn` / `packetsOut` | integer (uint64) | Packet counters |

### Deleting a Tunnel

```bash
curl -X DELETE http://loxilb:11111/netlox/v1/config/ipsec/tunnels/gw1-to-gw2 \
  -H "Authorization: Bearer <token>"
```

### Certificate Management

```bash
# Upload certificate
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/certificates \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "gateway-cert",
    "certificate": "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----"
  }'

# List certificates
curl http://loxilb:11111/netlox/v1/config/ipsec/certificates/all \
  -H "Authorization: Bearer <token>"

# Upload CA certificate
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/ca-certificates \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "root-ca",
    "certificate": "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----"
  }'

# Validate certificate
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/certificates/validate \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "gateway-cert",
    "certificate": "-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----"
  }'

# Get IPsec statistics
curl http://loxilb:11111/netlox/v1/config/ipsec/stats \
  -H "Authorization: Bearer <token>"

# Get all Security Associations
curl http://loxilb:11111/netlox/v1/config/ipsec/sas/all \
  -H "Authorization: Bearer <token>"
```

## Configuration Scenarios

### Scenario 1: Site-to-Site with Certificate Authentication

Full PKI setup for production inter-site encryption. Uses IKEv2 with strong ciphers and automatic rekeying.

```bash
# 1. Upload CA certificate
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/ca-certificates \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "corp-ca", "certificate": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"}'

# 2. Upload gateway certificate
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/certificates \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "gw1-cert",
    "certificate": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----",
    "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
  }'

# 3. Create tunnel with certificate auth
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/tunnels \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "site1-to-site2",
    "localIp": "203.0.113.1",
    "remoteIp": "198.51.100.1",
    "authMode": "cert",
    "certName": "gw1-cert",
    "caCertName": "corp-ca",
    "localId": "gw1.corp.example.com",
    "remoteId": "gw2.corp.example.com",
    "ikeVersion": "ikev2",
    "ikeEncryption": "aes256-sha512-modp4096",
    "espEncryption": "aes256-sha256",
    "espLifetime": 3600,
    "rekey": true,
    "auto": "start",
    "selector": {"srcCidr": "10.1.0.0/16", "dstCidr": "10.2.0.0/16"},
    "dpd": {"action": "restart", "delay": 30, "timeout": 150}
  }'

# 4. Enable fast-path and hardware offload
curl -X PUT http://loxilb:11111/netlox/v1/config/ipsec \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"fastPathEnabled": true, "hwOffloadEnabled": true, "hwOffloadType": "qat", "antiReplayEnabled": true}'
```

**When to use:** Production inter-site or inter-data-center encryption. Certificate rotation can be automated without changing tunnel configuration.

### Scenario 2: Quick PSK Tunnel for Dev/Test

Pre-shared key for rapid tunnel deployment. Minimal configuration, suitable for development and testing environments.

```bash
curl -X POST http://loxilb:11111/netlox/v1/config/ipsec/tunnels \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "dev-tunnel",
    "localIp": "10.1.0.1",
    "remoteIp": "10.2.0.1",
    "authMode": "psk",
    "psk": "dev-shared-secret-2025",
    "ikeVersion": "ikev2",
    "auto": "start",
    "selector": {"srcCidr": "192.168.1.0/24", "dstCidr": "192.168.2.0/24"},
    "dpd": {"action": "restart", "delay": 60, "timeout": 300}
  }'
```

**When to use:** Development environments, quick proof-of-concept testing, or temporary tunnels where PKI infrastructure is not yet available.

## Supported Algorithms

### Encryption

| Algorithm | Strength | Recommendation |
|-----------|----------|----------------|
| `aes256` | Strong | **Recommended** for new deployments |
| `aes128` | Good | Acceptable where performance is constrained |
| `3des` | Legacy | Not recommended — use only for interoperability |

### Integrity

| Algorithm | Strength | Recommendation |
|-----------|----------|----------------|
| `sha512` | Strong | **Recommended** for high-security deployments |
| `sha256` | Good | Acceptable for most deployments |
| `sha1` | Legacy | Not recommended — known collision weaknesses |

### Diffie-Hellman Groups

| Group | Strength | Recommendation |
|-------|----------|----------------|
| `modp4096` | Strong | **Recommended** for high-security |
| `modp2048` | Good | Acceptable minimum for production |
| `modp1024` | Legacy | Not recommended — below NIST recommendations |

## Verify

```bash
curl http://loxilb:11111/netlox/v1/config/ipsec/tunnels/all \
  -H "Authorization: Bearer <token>"

# Response (200):
# [{
#   "name": "gw1-to-gw2",
#   "localIp": "10.1.0.1",
#   "remoteIp": "10.2.0.1",
#   "state": "up",
#   "bytesIn": 1048576,
#   "bytesOut": 2097152,
#   "packetsIn": 12000,
#   "packetsOut": 24000
# }]
```

Check `state` is `"up"` and traffic counters are incrementing.

## Troubleshoot

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Tunnel stuck in "connecting" | PSK mismatch or IKE ports blocked | Verify PSK on both sides; ensure UDP 500/4500 are open |
| DPD triggering frequently | Unstable network path | Increase `dpd.delay` and `dpd.timeout` |
| Certificate auth failing | Expired cert or broken CA chain | Check cert dates; verify CA cert in cacerts directory |
| Low throughput | Software crypto bottleneck | Enable `fastPathEnabled` and `hwOffloadEnabled` |
| MTU-related packet loss | IPsec overhead exceeds path MTU | Lower `mtu` setting (try 1380 or 1360) |

## See Also

- [IPsec API Reference](../reference/api.md#ipsec)
- [Secure Dataplane Overview](secure-dataplane.md) — IPsec vs mTLS vs eBPF comparison
- [mTLS Configuration](mtls.md) — L7 mutual authentication (complementary to L3 IPsec)
- [Deployment Scenarios](deployment-scenarios.md) — Encrypted Node Mesh deployment pattern
- [Security Gateway Overview](overview.md) — Full security architecture
- [Configuration Reference](configuration-reference.md) — Quick-reference for all Security Gateway config fields
