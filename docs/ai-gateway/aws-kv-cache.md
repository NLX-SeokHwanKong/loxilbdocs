# AWS KV Cache Deployment

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](../getting-started/installation.md) for enterprise binary setup.

## Overview

This page documents deploying KV cache-aware AI Gateway routing on **AWS EKS** infrastructure. The core KV routing configuration is the same as documented in [KV Caching](kv-caching.md) — this page adds AWS-specific networking considerations.

!!! note "No AWS-Specific Code"
    No AWS-specific loxilb code exists. This is a deployment guide applying standard KV routing on AWS infrastructure. All configuration fields are documented in [KV Caching](kv-caching.md) and [Configuration Reference](configuration-reference.md).

## Architecture on AWS

A typical AWS deployment runs:

- **loxilb** in external mode on EKS (see [EKS External Mode](../eks-external.md) for the base pattern)
- **vLLM pods** on GPU node groups — AWS instances with NVIDIA GPUs (p4d for A100, p5 for H100, g5 for A10G)
- **loxilb KV subscriber** connecting to vLLM ZMQ endpoints across the VPC

```
┌─────────────────────────────────────────────────┐
│  AWS VPC                                         │
│                                                   │
│  ┌──────────────┐      ┌──────────────────────┐  │
│  │ loxilb node  │      │ GPU Node Group       │  │
│  │ (external)   │      │                      │  │
│  │              │◄─────│ vLLM Pod 1 (:5557)   │  │
│  │  KV Subscriber      │ vLLM Pod 2 (:5557)   │  │
│  │  ZMQ :5557  │◄─────│ vLLM Pod 3 (:5557)   │  │
│  └──────────────┘      └──────────────────────┘  │
│         │                                         │
│         ▼                                         │
│  NLB / Direct VIP                                 │
└─────────────────────────────────────────────────┘
```

## AWS Networking Requirements

### ZMQ Port Security Group

The ZMQ PUB/SUB connection between loxilb and vLLM instances requires port **5557** (or your configured `kvZmqPort`) to be open:

```
# Security Group Rule: loxilb → vLLM ZMQ
Type:        Custom TCP
Protocol:    TCP
Port Range:  5557
Source:      <loxilb-security-group-id>
Description: loxilb KV cache ZMQ subscriber
```

**Both directions matter:** loxilb initiates the ZMQ SUB connection to each vLLM endpoint's PUB socket. Ensure the security group on the GPU node group allows inbound TCP 5557 from the loxilb security group.

### ENI Considerations

GPU instances (p4d, p5, g5) may have **limited ENI slots**. When running multiple vLLM pods per node:

- Use **pod-level networking** (AWS VPC CNI) rather than host networking to avoid ENI exhaustion
- Verify that each vLLM pod gets a routable IP that loxilb can reach for both HTTP (serving) and ZMQ (KV block publishing)

### Multi-AZ Deployment

For high availability across AWS Availability Zones, reference [Multi-AZ HA on AWS](../aws-multi-az.md) for the base HA deployment pattern. Layer KV-exact routing config on top:

- KV cache routing works across AZs — loxilb's ZMQ subscriber connects to vLLM instances in all AZs
- Cross-AZ ZMQ traffic incurs additional latency (~1ms) but this is in the background (block inventory updates), not on the request path
- For latency-sensitive deployments, consider AZ-affinity with fallback to cross-AZ routing

## Configuration

Standard KV-exact routing config applies — no AWS-specific configuration fields:

```yaml
# KV-Exact Routing on AWS EKS
# Configuration is the same as standard KV routing
# See: docs/ai-gateway/kv-caching.md for full field reference
serviceArguments:
  vip: "10.0.0.100"            # VIP on loxilb external node
  port: 443
  protocol: "tcp"
  mode: 4                       # LBModeFullProxy required
  sel: 8                        # LbSelCHWBL
  kvExactMode: 1                # Enable KV-exact routing
  kvBlockSize: 16
  kvHashAlgo: "sha256_cbor"
  kvZmqPort: 5557               # Must match security group rule
  kvWarmupSec: 30
endpoints:
  - endpointIP: "10.0.1.10"     # vLLM pod IP (AWS VPC CNI)
    targetPort: 8080
  - endpointIP: "10.0.1.11"
    targetPort: 8080
  - endpointIP: "10.0.1.12"
    targetPort: 8080
```

## EKS Service Setup

loxilb runs as an external load balancer on EKS. Two common patterns:

1. **NLB frontend** — AWS Network Load Balancer forwards client traffic to loxilb's VIP. loxilb handles L7 AI Gateway routing.
2. **Direct VIP** — loxilb advertises the VIP directly via BGP to the AWS VPC router (requires Transit Gateway or custom routing).

See [EKS External Mode](../eks-external.md) for detailed setup instructions.

## See Also

- [KV Caching](kv-caching.md) — Core KV cache routing configuration and concepts
- [EKS External Mode](../eks-external.md) — Base EKS deployment pattern for loxilb
- [Multi-AZ HA on AWS](../aws-multi-az.md) — High availability deployment on AWS
- [Configuration Reference](configuration-reference.md) — All AI Gateway config fields
