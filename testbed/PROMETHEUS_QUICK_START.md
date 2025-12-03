# Prometheus Quick Start

## 🚀 **Quick Installation**

```bash
cd "/home/kali/Desktop/MSc Research Project/MSc-Research-Project-/testbed"
./scripts/10-install-prometheus.sh
```

**Installation time:** 3-5 minutes

## 📊 **Access Prometheus**

### **1. Start Port Forward:**
```bash
kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
```

### **2. Open Browser:**
```
http://localhost:9090
```

## 📈 **Access Grafana**

### **1. Start Port Forward:**
```bash
kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80
```

### **2. Open Browser:**
```
http://localhost:3000
```

**Login:**
- Username: `admin`
- Password: `admin`

## 🔍 **Key Prometheus Queries for Your Thesis**

### **Performance Metrics:**

**Network Throughput (Receive):**
```promql
rate(container_network_receive_bytes_total{namespace="tenant-a"}[5m])
```

**Network Throughput (Transmit):**
```promql
rate(container_network_transmit_bytes_total{namespace="tenant-a"}[5m])
```

**CPU Usage:**
```promql
rate(container_cpu_usage_seconds_total{namespace="tenant-a"}[5m])
```

**Memory Usage:**
```promql
container_memory_working_set_bytes{namespace="tenant-a"}
```

### **Cilium-Specific Metrics:**

**Cilium Drop Rate (Blocked Traffic):**
```promql
rate(cilium_drop_total[5m])
```

**Cilium Policy Enforcement:**
```promql
rate(cilium_policy_l7_total[5m])
```

**Cilium Flow Rate:**
```promql
rate(cilium_flows_total[5m])
```

**Cilium CPU Usage:**
```promql
rate(process_cpu_seconds_total{job="cilium"}[5m])
```

**Cilium Memory Usage:**
```promql
process_resident_memory_bytes{job="cilium"}
```

## 📤 **Export Metrics for Analysis**

```bash
./scripts/11-export-prometheus-metrics.sh
```

This exports all metrics to: `results/prometheus-metrics/`

## 🎯 **For Your Thesis**

### **Compare Scenarios:**

1. **Run Baseline tests** → Query Prometheus
2. **Apply NetworkPolicy** → Query Prometheus  
3. **Apply CiliumNetworkPolicy** → Query Prometheus
4. **Compare metrics** → Create tables and charts

### **Screenshots to Take:**

- Prometheus query results showing performance differences
- Grafana dashboards with Cilium metrics
- Comparison charts between scenarios

### **Data Collection:**

Metrics are automatically exported when running:
```bash
./scripts/08-comprehensive-tests.sh
```

## 📚 **Full Documentation**

See `docs/PROMETHEUS_GUIDE.md` for complete guide with:
- All available queries
- Dashboard configuration
- Troubleshooting
- Advanced usage

