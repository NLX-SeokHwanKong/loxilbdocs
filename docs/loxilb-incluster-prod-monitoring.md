# LoxiLB Monitoring System

## 📌 Overview
LoxiLB's **Monitoring System** provides **real-time visibility** into traffic management, load balancing efficiency, 
and firewall policies. It integrates **Prometheus, Thanos, Alertmanager, and Grafana** 
to offer **scalable, high-availability monitoring**.

## 📊 Why Use Thanos, Alertmanager, and MinIO in Production?
### **1️⃣ Thanos: Long-Term Storage & HA Prometheus**
Thanos extends Prometheus to provide:

✅ **High Availability (HA):** Aggregates multiple Prometheus instances to prevent data loss.

✅ **Short-Term Storage via Sidecar:** Acts as a bridge between Prometheus and Thanos Querier.

✅ **Long-Term Storage via MinIO:** Stores historical metrics in object storage (e.g., MinIO, AWS S3).

✅ **Deduplication:** Avoids duplicate metrics from HA Prometheus.

✅ **Global Querying:** Allows queries across multiple Prometheus instances.

### **2️⃣ Alertmanager: Centralized Alerting**

✅ **Manages alerts centrally** for multiple Prometheus instances.

✅ **Silences unnecessary alerts** and prevents spamming.

✅ **Routes alerts to different receivers** (Slack, Email, PagerDuty, Webhooks).

✅ **Groups related alerts** to avoid duplicate notifications.

### **3️⃣ MinIO: Scalable Object Storage for Thanos**

✅ **Stores Prometheus historical data** in an S3-compatible format.

✅ **Scales efficiently** for large datasets.

✅ **Ensures data retention policies** are met for compliance.

## 📊 Architecture
### **LoxiLB Monitoring Stack**
```
+-----------------------+    +--------------------+    +----------------------+
|     LoxiLB Nodes      |--->|   Node Exporter    |--->|      Prometheus      |
| (LB, Traffic Stats)   |    | (Node Metrics)     |    | (Scrapes Metrics)    |
+-----------------------+    +--------------------+    +---------+------------+
                                                                 |
+---------------------------+   +-------------------+            |
|        Alertmanager       |-->|    Thanos Ruler   |------------|
| (Sends Notifications)     |   | (Manages Alerts)  |            |
+---------------------------+   +-------------------+            |
                                                                 v
+-----------------------+    +----------------------+    +------------------+
|    Thanos Sidecar     |--->|    Thanos Querier    |--->|      Grafana     |
| (Short-term Storage)  |    | (Aggregates Data)    |    | (Visualize Data) |
+-----------------------+    +----------------------+    +------------------+
                                     ^
+----------------------------+       |
|        MinIO (S3)          |-------|
| (Long-term Storage)        |
+----------------------------+
```

## 1️. Install Node Exporter
```sh
wget https://raw.githubusercontent.com/loxilb-io/kube-loxilb/blob/main/manifest/in-cluster-prod-monitoring/node-exporter-ds.yaml

# Modify node-exporter-ds.yaml
kubectl apply -f node-exporter-ds.yaml
```

## 2️. Deploy Alert manager
🔧 Customizing Alert manager Configuration
Modify **email alerts** in `alert-manager.yaml`:
```yaml
data:
  alertmanager.yml: |
    global:
      resolve_timeout: 5m
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'your-gmail@example.com'
      smtp_auth_username: 'your-gmail@example.com'
      smtp_auth_password: 'your-app-password'  # Generate an App Password
      smtp_require_tls: true
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 3h
      receiver: 'email-alert'

    receivers:     
      - name: 'email-alert'
        email_configs:
          - to: 'receiver-email@example.com'
            from: 'your-gmail@example.com'
            smarthost: 'smtp.gmail.com:587'
            auth_username: 'your-gmail@example.com'
            auth_password: 'your-app-password'
            require_tls: true 
```
🔹 **Replace `your-email@example.com`, `receiver-email@example.com` and `your-app-password`, before applying!**

#### (Optional) 📌 Slack Integration Use Case
**Why Use Slack for Alerts?**

✅ Real-time notifications for incidents.

✅ Team collaboration – alerts can be acknowledged in Slack.

✅ Multiple channels – route alerts to different teams (e.g., #infra-alerts, #security).

Example Configuration
```yaml
receivers:
  - name: 'slack-alert'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR_SLACK_WEBHOOK'
        channel: '#alerts'
        send_resolved: true
        title: '🔥 [Alert] {{ .CommonAnnotations.summary }}'
        text: '🚨 *Alert:* {{ .CommonLabels.alertname }}\n📍 *Instance:* {{ .CommonLabels.instance }}\n📊 *Severity:* {{ .CommonLabels.severity }}\n📅 *Time:* {{ .StartsAt }}'
```
🔹 Modify channel to your Slack channel **(#alerts)**.
🔹 Replace **YOUR_SLACK_WEBHOOK** with your Slack Webhook URL.

#### (Optional) 📌 Webhook Integration Use Case
**Why Use Webhooks for Alerts?**

✅ Integrates with custom automation tools – trigger incident response workflows.

✅ Routes alerts to external monitoring systems (e.g., ticketing systems, AIOps platforms).

✅ Triggers auto-scaling events – if an alert is fired, scale resources dynamically.

Example Configuration
```yaml
receivers:
  - name: 'webhook-alert'
    webhook_configs:
      - url: 'http://your-webhook-endpoint'
        send_resolved: true
```
🔹 Replace **http://your-webhook-endpoint** with your actual webhook URL.

🔹 Use a webhook to trigger autoscaling, restart services, or log incidents.

#### **🔗 References for Aler tmanager Integration:**
- **Email Configuration**: [Prometheus Alertmanager Email Setup](https://prometheus.io/docs/alerting/latest/configuration/#email_config)
- **Slack Configuration**: [Prometheus Alertmanager Slack Setup](https://prometheus.io/docs/alerting/latest/configuration/#slack_config)
- **Webhook Integration**: [Prometheus Alertmanager Webhooks](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config)

### Install of Alert Manager

```sh
wget https://raw.githubusercontent.com/loxilb-io/kube-loxilb/blob/main/manifest/in-cluster-prod-monitoring/alert-manager.yaml
# Modify alert-manager.yaml
kubectl apply -f alert-manager.yaml
```

## 3️. Deploy Thanos Components (thanos.yaml)

(1) **Customizing Thanos Configuration(Used by Thanos Sidecar)**:

This Prometheus is set up to work with Thanos and collect metrics efficiently.
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      scrape_timeout: 10s
      evaluation_interval: 15s
      external_labels:
        cluster: "prometheus-cluster"
        replica: "${POD_NAME}"
```
**🔹 What This Does?**
| **Setting** | **Description** | **Customization Tips** |
|------------|----------------|------------------------|
| scrape_interval: 15s | Defines how often Prometheus collects metrics | Increase it (e.g., 30s) for less frequent collection |
| evaluation_interval: 15s | Determines how often alerts are evaluated | Match it to scrape_interval for consistency |
| external_labels: | Helps Thanos differentiate Prometheus instances | Unique values ensure correct data grouping |

🔹 **External labels** are crucial for **Thanos Querier** to identify metrics correctly, so **don’t remove them!**

This Thanos Sidecar ensures that Prometheus data is **stored and accessible long-term**.
```yaml
- name: thanos-sidecar
  image: quay.io/thanos/thanos:v0.34.1
  args:
    - sidecar
    - "--prometheus.url=http://localhost:9090"
    - "--objstore.config-file=/etc/thanos/objstore.yml"
    - "--tsdb.path=/prometheus"
    - "--grpc-address=0.0.0.0:10901"
```
### **🔹 What This Does?**
| **Setting** | **Description** | **Customization Tips** |
|------------|----------------|------------------------|
| --prometheus.url=http://localhost:9090 | Connects to Prometheus API | Keep this as localhost in single-node setups |
| --objstore.config-file=/etc/thanos/objstore.yml | Defines **MinIO/S3 storage** | Modify to fit your storage provider |
| --grpc-address=0.0.0.0:10901 | Enables gRPC API for Thanos Querier | **Do not disable** if using Thanos Querier |

📌 **Reference:** [Thanos Sidecar Docs](https://thanos.io/tip/components/sidecar/)

(2) **Configuring Alerting Configuration**
```yaml
    alerting:
      alertmanagers:
      - static_configs:
        - targets: []
        scheme: http
        timeout: 10s
        api_version: v2
```
**🔹 What This Does?**
| **Setting** | **Description** | **Customization Tips** |
|------------|----------------|------------------------|
| alertmanagers: | Specifies where alerts should be sent | Set the correct **Alertmanager service** |
| timeout: 10s | How long Prometheus waits before failing alert delivery | Increase if your Alertmanager is slow |

(3) **Configuring Prometheus Scrape Jobs**

These jobs define what **metrics sources** are collected.
```yaml
    scrape_configs:
      - job_name: 'loxilb'
        metrics_path: /netlox/v1/metrics
        static_configs:
          - targets:
            - 'loxilb-lb-service.kube-system.svc.cluster.local:11111'
      - job_name: 'node-exporter'
        static_configs:
          - targets: ['node-exporter.monitoring.svc.cluster.local:9100']
```
**🔹 What This Does?**
| **Job Name** | **What It Collects** | **Why It's Important** |
|-------------|----------------------|------------------------|
| loxilb | Collects **LoxiLB-specific** metrics | Helps monitor **load balancer performance** |
| node-exporter | Gathers **system-level metrics** | Tracks **CPU, memory, and disk usage** |

🔹 **Want to add Kubernetes-specific metrics?**
```yaml
- job_name: 'kube-state-metrics'
  static_configs:
    - targets: ['kube-state-metrics.monitoring.svc.cluster.local:8080']
```
**📌 Learn More:** [Prometheus Scrape Config Docs](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config)

(4) **MinIO Configuration for Thanos Storage**
---
MinIO (or S3) is used as **long-term storage** for metrics.
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: thanos-objstore
  namespace: monitoring
data:
  objstore.yml: |
    type: s3
    config:
      bucket: "prometheus"
      endpoint: "minio-service:9000"
      access_key: "minio"
      secret_key: "minio123"
      insecure: true
```
### **🔹 What This Does?**
| **Setting** | **Description** | **Customization Tips** |
|------------|----------------|------------------------|
| type: s3 | Defines storage type | Use s3 for **AWS S3, MinIO, or compatible storage** |
| bucket: "prometheus" | Storage location | Adjust based on **your provider** |
| endpoint: "minio-service:9000" | MinIO/S3 server address | Change if using **external S3** |
| access_key & secret_key | Authentication credentials | **Replace with secure values** |

📌 **Reference:** [Thanos Object Storage Docs](https://thanos.io/tip/thanos/storage/)

Installation of Thanos, Minio and Prometheus
```sh
wget https://raw.githubusercontent.com/loxilb-io/kube-loxilb/blob/main/manifest/in-cluster-prod-monitoring/thanos.yaml
wget https://raw.githubusercontent.com/loxilb-io/kube-loxilb/blob/main/manifest/in-cluster-prod-monitoring/thanos-ruler-deployment.yaml
# Modify thanos.yaml and thanos-ruler-deployment.yaml
kubectl apply -f thanos.yaml
kubectl apply -f thanos-ruler-deployment.yaml
```

## 4️. Install Thanos Ruler(thanos-ruler-deployment.yaml)

Thanos Ruler evaluates **alerting and recording rules** centrally, instead of relying on individual Prometheus instances.

#### **🚀 Why Use Thanos Ruler?**

✅ **Centralized Alerting** - Ensures alerts are evaluated across all Prometheus instances.

✅ **Historical Querying** - Uses Thanos Querier to analyze past data, enabling more accurate alerting.

✅ **Reduces Load on Prometheus** - Moves alert evaluations from Prometheus, improving performance.

#### **🛠 Customizing Alert Rules**
Modify alert thresholds based on your environment:

| **Alert Name** | **Expression** | **Duration** | **Severity** | **Description** |
|--------------|---------------|------------|------------|----------------|
| **Node Down** | up{job="node-exporter"} == 0 | 2m | Critical | The node-exporter instance is unreachable. |
| **High CPU Usage** | 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90 | 5m | Warning | CPU usage exceeds 90% for 5 minutes. |
| **High Memory Usage** | (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 < 10 | 5m | Warning | Available memory drops below 10%. |
| **High Load Average** | node_load1 > (count(node_cpu_seconds_total{mode="idle"}) * 2) | 5m | Critical | Load average exceeds twice the number of CPU cores. |
| **Low Disk Space** | (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"}) * 100 < 10 | 10m | Critical | Disk space drops below 10%. |
| **Network Interface Down** | node_network_up{device!~"^(lo\|docker0\|kube-bridge\|cni0\|kube-ipvs0\|nodelocaldns\|vxlan.calico\|eno1\|eno2)$"} == 0 | 2m | Warning | A network interface is down. |
| **High Network Traffic** | rate(node_network_receive_bytes_total[5m]) > 10000000000 or rate(node_network_transmit_bytes_total[5m]) > 10000000000 | 5m | Warning | Network traffic exceeds 10GB/s. |

#### **📊 Dynamic Load-Based Alerts**
```yaml
- alert: TrafficSurge
  expr: rate(processed_bytes[5m]) > 500000000
  for: 3m
  labels:
    severity: warning
  annotations:
    summary: "High network traffic detected"
    description: "Traffic exceeded 500MB per second in the last 5 minutes."
```

#### **🔄 Grouping & Aggregation**
If monitoring multiple instances, use `group()` to group metrics before alerting:
```yaml
- alert: BackendFailure
  expr: sum(unhealthy_host_count) by (service) > 0
  for: 2m
  labels:
    severity: warning
  annotations:
    summary: "Backend failure detected"
```

Installation of Thanos Alert Ruler
```sh
wget https://raw.githubusercontent.com/loxilb-io/kube-loxilb/blob/main/manifest/in-cluster-prod-monitoring/thanos-ruler-deployment.yaml
# Modify thanos-ruler-deployment.yaml
kubectl apply -f thanos-ruler-deployment.yaml
```

#### **🔗 References for Thanos Ruler**
- **Thanos Ruler Docs:** [Thanos Ruler Configuration](https://thanos.io/tip/components/rule/)
- **Alerting & Recording Rules:** [Prometheus Rule Configuration](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)
- **Querying Past Data with Thanos Querier:** [Thanos Query Docs](https://thanos.io/tip/components/query/)

## 5. Install Grafana(thanos-grafana.yaml)

Installation of Grafana

```sh
kubectl apply -f https://raw.githubusercontent.com/loxilb-io/kube-loxilb/blob/main/manifest/in-cluster-prod-monitoring/thanos-grafana.yaml
```

## **🌍 Exposed Services Overview**

| **Service Name**       | **Description**                          | **LoadBalancer Port** | **Target Port** |
|------------------------|------------------------------------------|-----------------------|-----------------|
| **Grafana**            | Grafana Dashboard                        | 59301               | 3000          |
| **Thanos Querier**     | Aggregates and queries metrics           | 59303               | 9090          |
| **Thanos Ruler**       | Evaluates alerting and recording rules   | 59305               | 10902         |
| **Alertmanager**       | Manages alerts and notifications         | 59304               | 9093          |
| **Loki**               | Centralized log aggregation              | 59302               | 3100          |

---

## 📊 Summary

✅ **End-to-end observability for LoxiLB**

✅ **Real-time traffic monitoring & alerts**

✅ **Short-term storage via Thanos Sidecar**

✅ **Long-term storage via MinIO**

✅ **Centralized alerting with Alertmanager**

✅ **Visualized insights via Grafana**
