# Migrating from Community Edition

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](installation.md) for enterprise binary setup.

## Overview

Existing community loxilb users can upgrade to loxilb-enterprise to access the AI Gateway, Security Gateway, and advanced Network Gateway features. The enterprise binary is a **superset of community** — all existing configurations, rules, and integrations continue to work without modification.

## What Changes

| Component | Community | Enterprise |
|---|---|---|
| Binary name | `loxilb` | `loxilb-enterprise` |
| Container image | `ghcr.io/loxilb-io/loxilb` | `ghcr.io/netlox-dev/loxilb-enterprise` |
| CLI tool | `loxicmd` | `loxicmd` (same) |
| REST API base | `http://localhost:11111` | `http://localhost:11111` (same) |
| Configuration format | YAML/CLI | YAML/CLI (same, with additional enterprise options) |
| kube-loxilb | Compatible | Compatible (same CRDs, additional enterprise CRDs) |

**Key points:**

- All existing community configurations **remain compatible**
- Existing load balancer rules, endpoints, and conntrack entries work identically
- New enterprise features are **disabled by default** — opt-in activation only
- The REST API is backward-compatible; enterprise endpoints are additive
- kube-loxilb works with both community and enterprise without changes

## Feature Comparison

For a complete feature-by-feature comparison, see the [Unified Gateway Platform](../concepts/unified-gateway.md#community-edition-vs-enterprise) page.

| Feature | Community | Enterprise |
|---|:---:|:---:|
| L4 Load Balancing | :material-check: | :material-check: |
| HA / Clustering | :material-check: | :material-check: |
| Kubernetes Integration | :material-check: | :material-check: |
| eBPF Dataplane | :material-check: | :material-check: |
| AI Gateway (LLM routing, KV caching) | :material-close: | :material-check: |
| Security Gateway (OPA, Presidio, LlamaFirewall) | :material-close: | :material-check: |
| Advanced Networking (Egress LB, DSR, NAT64) | :material-close: | :material-check: |
| User Management / RBAC | :material-close: | :material-check: |

## Migration Steps

### Step 1: Back Up Current Configuration

Before upgrading, export your current load balancer rules and configuration:

```bash
# Export current LB rules
docker exec loxilb loxicmd get lb -o json > lb-rules-backup.json

# Export current conntrack state (optional)
docker exec loxilb loxicmd get conntrack -o json > conntrack-backup.json
```

### Step 2: Replace Container Image or Binary

=== "Docker"

    ```bash
    # Stop the community container
    docker stop loxilb && docker rm loxilb

    # Start the enterprise container with the same configuration
    docker run -d --privileged --name loxilb-enterprise \
      -v /dev/log:/dev/log \
      --net=host \
      ghcr.io/netlox-dev/loxilb-enterprise:latest
    ```

=== "Kubernetes"

    Update your deployment manifest to use the enterprise image:

    ```yaml
    # Before (community)
    image: ghcr.io/loxilb-io/loxilb:latest

    # After (enterprise)
    image: ghcr.io/netlox-dev/loxilb-enterprise:latest
    ```

    Apply the updated manifest:

    ```bash
    kubectl apply -f your-loxilb-deployment.yaml
    ```

=== "Bare Metal"

    ```bash
    # Stop the community service
    sudo systemctl stop loxilb

    # Replace the binary
    sudo mv /usr/local/bin/loxilb /usr/local/bin/loxilb.community.bak
    sudo mv loxilb-enterprise /usr/local/bin/loxilb-enterprise

    # Update the systemd service file to use loxilb-enterprise
    sudo sed -i 's|/usr/local/bin/loxilb|/usr/local/bin/loxilb-enterprise|' \
      /etc/systemd/system/loxilb.service

    # Restart
    sudo systemctl daemon-reload
    sudo systemctl start loxilb
    ```

### Step 3: Verify Existing Services

After upgrading, verify that all existing load balancer rules are intact:

```bash
docker exec loxilb-enterprise loxicmd get lb
```

Compare the output with your backup from Step 1. All rules should be present and active.

Test connectivity to your existing services to confirm traffic is flowing correctly.

### Step 4: Enable Enterprise Features

Enterprise features are opt-in. Enable them as needed:

```bash
# Example: Enable AI Gateway features
docker exec loxilb-enterprise loxicmd set ai-gateway --enable

# Example: Enable OPA policy enforcement
docker exec loxilb-enterprise loxicmd set security --opa-enable
```

Refer to each pillar's documentation for detailed configuration:

- [AI Gateway](../ai-gateway/overview.md) — LLM routing, KV caching, vLLM integration
- [Security Gateway](../security-gateway/overview.md) — OPA, Presidio, LlamaFirewall, rate limiting
- [Network Gateway](../network-gateway/overview.md) — Egress LB, DSR, NAT64
- [User Management](../operations/user-management.md) — RBAC, namespace isolation

## Getting Help

- **Enterprise Support:** Contact support@netlox.io for enterprise customers
- **Community Slack:** [Join the loxilb Slack workspace](https://join.slack.com/t/loxilb/shared_invite/zt-2b3xx14wg-P7WHj5C~OEON_jviF0ghcQ)
- **GitHub Issues:** [loxilb-io/loxilb](https://github.com/loxilb-io/loxilb/issues)
