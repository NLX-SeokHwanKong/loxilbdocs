# Installation

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [System Requirements](../reference/system-requirements.md) for detailed platform requirements.

## System Requirements

- **Linux kernel:** 5.10 or later (5.15+ recommended for full eBPF feature support)
- **Architecture:** amd64, arm64
- **Memory:** 2 GB minimum, 4 GB recommended
- **Disk:** 500 MB for binary and logs

For detailed requirements, see the [System Requirements](../reference/system-requirements.md) page.

## Installation Methods

=== "Docker"

    Pull and run the enterprise container image:

    ```bash
    docker pull ghcr.io/netlox-dev/loxilb-enterprise:latest
    docker run -d --privileged --name loxilb-enterprise \
      -v /dev/log:/dev/log \
      --net=host \
      ghcr.io/netlox-dev/loxilb-enterprise:latest
    ```

=== "Kubernetes"

    Deploy loxilb-enterprise using the enterprise manifest:

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/loxilb-io/kube-loxilb/main/manifest/enterprise/kube-loxilb-enterprise.yaml # (1)!
    ```

    1. Contact your account team for the enterprise deployment manifest URL.

    <!-- TODO: Confirm enterprise Kubernetes manifest URL -->

    For Helm-based deployments:

    ```bash
    helm repo add loxilb https://loxilb-io.github.io/helm-charts
    helm install loxilb-enterprise loxilb/loxilb-enterprise
    ```

    <!-- TODO: Confirm Helm chart availability -->

=== "Bare Metal"

    Download the enterprise binary and install as a systemd service:

    ```bash
    # Download the enterprise binary
    curl -LO https://downloads.netlox.io/loxilb-enterprise/latest/loxilb-enterprise # (1)!
    chmod +x loxilb-enterprise
    sudo mv loxilb-enterprise /usr/local/bin/
    ```

    1. Contact sales@netlox.io for the enterprise download URL and license key.

    <!-- TODO: Confirm enterprise binary download URL -->

    Create a systemd service file:

    ```bash
    sudo tee /etc/systemd/system/loxilb-enterprise.service << 'EOF'
    [Unit]
    Description=loxilb-enterprise Unified Gateway
    After=network.target

    [Service]
    Type=simple
    ExecStart=/usr/local/bin/loxilb-enterprise
    Restart=on-failure
    RestartSec=5
    LimitNOFILE=65536

    [Install]
    WantedBy=multi-user.target
    EOF
    ```

    Enable and start the service:

    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable loxilb-enterprise
    sudo systemctl start loxilb-enterprise
    ```

## Verify Installation

After installation, verify that loxilb-enterprise is running:

=== "Docker"

    ```bash
    docker logs loxilb-enterprise 2>&1 | head -20
    ```

    You should see startup messages indicating the eBPF dataplane is loaded.

=== "Kubernetes"

    ```bash
    kubectl get pods -A | grep loxilb
    ```

    The loxilb-enterprise pod should show `Running` status.

=== "Bare Metal"

    ```bash
    sudo systemctl status loxilb-enterprise
    ```

    The service should show `active (running)`.

Verify the REST API is accessible:

```bash
curl -s http://localhost:11111/status | head
```

## Next Steps

- [Quick Start](quickstart.md) — Complete the 10-minute quickstart to create your first load balancer rule
- [Migrating from Community](migration-from-community.md) — If you are upgrading from community loxilb
- [Unified Gateway Platform](../concepts/unified-gateway.md) — Understand the three-pillar architecture
