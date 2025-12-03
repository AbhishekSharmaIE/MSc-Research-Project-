# Prometheus and Grafana Guide

This guide explains how to use Prometheus and Grafana for visualizing Cilium and Kubernetes metrics in your testbed.

## Installation

### Quick Install

```bash
cd testbed
./scripts/10-install-prometheus.sh
```

This will:
- Install Prometheus using Helm
- Install Grafana for visualization
- Configure Cilium metrics scraping
- Set up pre-configured dashboards

### Installation Time

The installation takes approximately 3-5 minutes. Be patient!

## Accessing Prometheus

### Port Forward

```bash
kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Then open: **http://localhost:9090**

### Useful Prometheus Queries

#### Cilium Metrics

**Cilium Drop Rate:**
```
rate(cilium_drop_total[5m])
```

**Cilium Policy Count:**
```
cilium_policy_count
```

**Cilium Flow Rate:**
```
rate(cilium_flows_total[5m])
```

**Cilium CPU Usage:**
```
rate(process_cpu_seconds_total{job="cilium"}[5m])
```

**Cilium Memory Usage:**
```
process_resident_memory_bytes{job="cilium"}
```

**Network Throughput (Receive):**
```
rate(container_network_receive_bytes_total[5m])
```

**Network Throughput (Transmit):**
```
rate(container_network_transmit_bytes_total[5m])
```

**Policy Enforcement Decisions:**
```
rate(cilium_policy_l7_total[5m])
```

**Cilium Endpoint Count:**
```
cilium_endpoint_count
```

#### Performance Metrics

**Pod CPU Usage:**
```
rate(container_cpu_usage_seconds_total{namespace="tenant-a"}[5m])
```

**Pod Memory Usage:**
```
container_memory_working_set_bytes{namespace="tenant-a"}
```

**Network Latency (if available):**
```
histogram_quantile(0.95, rate(cilium_http_request_duration_seconds_bucket[5m]))
```

## Accessing Grafana

### Port Forward

```bash
kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80
```

Then open: **http://localhost:3000**

**Default Credentials:**
- Username: `admin`
- Password: `admin`

### Pre-configured Dashboards

The installation includes:
- **Cilium Dashboard** (ID: 13332) - Pre-configured Cilium metrics
- **Kubernetes Cluster Monitoring** - Node and cluster metrics
- **Kubernetes Pod Monitoring** - Pod-level metrics

### Creating Custom Dashboards

1. Go to **Dashboards** → **New Dashboard**
2. Add panels with Prometheus queries
3. Save dashboard

## Exporting Metrics for Analysis

### Automatic Export (During Tests)

Metrics are automatically exported when running comprehensive tests:

```bash
./scripts/08-comprehensive-tests.sh
```

Metrics are saved to: `results/prometheus-metrics/`

### Manual Export

```bash
./scripts/11-export-prometheus-metrics.sh
```

This exports:
- Cilium drop metrics
- Cilium policy metrics
- Cilium flow metrics
- CPU and memory usage
- Network throughput

## Integration with Test Scripts

### Running Tests with Prometheus

Prometheus is automatically installed when running comprehensive tests:

```bash
# Prometheus will be installed automatically
./scripts/08-comprehensive-tests.sh
```

### Disable Prometheus Installation

If you don't want Prometheus installed:

```bash
INSTALL_PROMETHEUS=false ./scripts/08-comprehensive-tests.sh
```

## Querying Metrics for Thesis

### Example: Compare eBPF vs iptables Performance

**During Baseline (no policies):**
```promql
rate(container_network_receive_bytes_total{namespace="tenant-a"}[5m])
```

**During NetworkPolicy:**
```promql
rate(container_network_receive_bytes_total{namespace="tenant-a"}[5m])
```

**During CiliumNetworkPolicy:**
```promql
rate(container_network_receive_bytes_total{namespace="tenant-a"}[5m])
```

Compare the values to show performance difference.

### Example: Security Metrics

**Policy Enforcement Rate:**
```promql
rate(cilium_policy_l7_total[5m])
```

**Drop Rate (Blocked Traffic):**
```promql
rate(cilium_drop_total[5m])
```

## Troubleshooting

### Prometheus Not Scraping Cilium

Check if Cilium pods are labeled correctly:
```bash
kubectl get pods -n kube-system -l k8s-app=cilium
```

### Prometheus Pod Not Ready

Check pod status:
```bash
kubectl get pods -n monitoring
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
```

### Cannot Access Prometheus UI

1. Check port-forward is running
2. Verify service exists: `kubectl get svc -n monitoring`
3. Check firewall settings

### Metrics Not Appearing

1. Wait 1-2 minutes after installation
2. Check Prometheus targets: http://localhost:9090/targets
3. Verify Cilium is exposing metrics: `kubectl exec -n kube-system <cilium-pod> -- wget -qO- http://localhost:9962/metrics | grep cilium`

## Uninstalling Prometheus

```bash
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

## For Your Thesis

### Metrics to Document

1. **Performance Metrics:**
   - Network throughput (receive/transmit)
   - CPU utilization
   - Memory consumption
   - Latency (if available)

2. **Security Metrics:**
   - Policy enforcement rate
   - Drop rate (blocked traffic)
   - Flow count
   - Endpoint count

3. **Comparison Metrics:**
   - Baseline vs NetworkPolicy vs CiliumNetworkPolicy
   - eBPF vs iptables overhead

### Screenshots for Thesis

Take screenshots of:
- Prometheus query results showing performance differences
- Grafana dashboards showing Cilium metrics
- Comparison charts between scenarios

### Data Export

Export metrics as JSON for analysis:
```bash
./scripts/11-export-prometheus-metrics.sh
```

Then analyze the JSON files to create comparison tables.

