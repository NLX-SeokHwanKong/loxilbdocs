# Quick Start

!!! enterprise "Enterprise Feature"
    This feature requires loxilb-enterprise. It is not available in the community edition.
    See [Installation](installation.md) for enterprise binary setup.

Complete this guide in **10 minutes** to deploy loxilb-enterprise as a gateway and route traffic through it.

## Prerequisites

- Docker installed and running
- 10 minutes of time

If you have not installed loxilb-enterprise yet, see the [Installation](installation.md) guide.

## What You'll Build

You will deploy loxilb-enterprise as a gateway, create a load balancer rule to distribute traffic across two endpoints, verify the rule is active, and test traffic flow. This demonstrates the core gateway capability that all three pillars (AI, Security, Network) build upon.

## Step 1: Start loxilb-enterprise

```bash
docker run -d --privileged --name loxilb-enterprise \
  -v /dev/log:/dev/log \
  --net=host \
  ghcr.io/netlox-dev/loxilb-enterprise:latest
```

Wait a few seconds for the eBPF dataplane to initialize, then verify:

```bash
docker logs loxilb-enterprise 2>&1 | head -5
```

You should see startup messages confirming the enterprise binary is running.

## Step 2: Create a Load Balancer Rule

Use `loxicmd` inside the container to create a TCP load balancer rule that distributes traffic from a virtual IP to two backend endpoints:

```bash
docker exec -it loxilb-enterprise loxicmd create lb 10.10.10.1 \
  --tcp=80:8080 \
  --endpoints=192.168.1.10:1,192.168.1.11:1
```

This creates a rule that:

- Listens on **10.10.10.1:80** (TCP)
- Forwards to **192.168.1.10:8080** and **192.168.1.11:8080**
- Distributes traffic equally (weight 1 each)

## Step 3: Verify the Rule

```bash
docker exec -it loxilb-enterprise loxicmd get lb
```

Expected output:

```
| EXTERNAL IP | PORT | PROTOCOL | ENDPOINTS                            | STATE |
|-------------|------|----------|--------------------------------------|-------|
| 10.10.10.1  | 80   | tcp      | 192.168.1.10:8080,192.168.1.11:8080  | ok    |
```

## Step 4: Test Traffic

If you have backend services running on the endpoint addresses, you can test traffic routing:

```bash
curl http://10.10.10.1:80
```

For a self-contained test without real backends, verify the rule is programmed in the eBPF dataplane:

```bash
docker exec -it loxilb-enterprise loxicmd get conntrack
```

## Step 5: Explore the API

loxilb-enterprise exposes a REST API for programmatic management:

```bash
# List all load balancer rules
curl -s http://localhost:11111/netlox/v1/config/loadbalancer/all

# Get system status
curl -s http://localhost:11111/netlox/v1/config/conntrack/all
```

The full API reference is available at [API Reference](../reference/api.md).

## What's Next

You have a running loxilb-enterprise instance with a basic load balancer rule. From here, explore the three gateway pillars:

- [:octicons-arrow-right-24: AI Gateway](../ai-gateway/overview.md) — LLM routing, KV caching, vLLM integration
- [:octicons-arrow-right-24: Security Gateway](../security-gateway/overview.md) — OPA policies, PII detection, rate limiting
- [:octicons-arrow-right-24: Network Gateway](../network-gateway/overview.md) — Egress LB, DSR, NAT64, advanced proxy modes

## Clean Up

To remove the quickstart container:

```bash
docker stop loxilb-enterprise && docker rm loxilb-enterprise
```
