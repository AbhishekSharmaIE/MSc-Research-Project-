# Prometheus Installation Status

## ✅ **Installation Complete!**

Prometheus and Grafana have been successfully installed and are running.

### **Status:**
- ✅ Prometheus: Running
- ✅ Grafana: Running  
- ✅ Cilium Metrics: Being scraped
- ✅ Node Exporter: Running
- ✅ Kube State Metrics: Running

---

## 🚀 **Quick Access**

### **Prometheus UI:**

```bash
# Terminal 1: Port forward
kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090

# Browser: Open http://localhost:9090
```

**Verify Cilium metrics:**
- Go to: http://localhost:9090/targets
- Look for "cilium" job - should show as "UP"

### **Grafana UI:**

```bash
# Terminal 2: Port forward
kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80

# Browser: Open http://localhost:3000
```

**Login:**
- Username: `admin`
- Password: Get with: `kubectl get secret -n monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d && echo`
- Or try default: `admin`

---

## 📊 **Key Prometheus Queries**

### **Performance Metrics:**

```promql
# Network Throughput (Receive)
rate(container_network_receive_bytes_total{namespace="tenant-a"}[5m])

# Network Throughput (Transmit)
rate(container_network_transmit_bytes_total{namespace="tenant-a"}[5m])

# CPU Usage
rate(container_cpu_usage_seconds_total{namespace="tenant-a"}[5m])

# Memory Usage
container_memory_working_set_bytes{namespace="tenant-a"}
```

### **Cilium Metrics:**

```promql
# Cilium Drop Rate (Blocked Traffic)
rate(cilium_drop_total[5m])

# Cilium Policy Enforcement
rate(cilium_policy_l7_total[5m])

# Cilium Flow Rate
rate(cilium_flows_total[5m])

# Cilium CPU Usage
rate(process_cpu_seconds_total{job="cilium"}[5m])

# Cilium Memory Usage
process_resident_memory_bytes{job="cilium"}
```

---

## 📈 **For Your Thesis**

### **Data Collection:**

1. **Run tests** - Metrics are automatically collected
2. **Query Prometheus** - Use the queries above
3. **Export metrics** - Run: `./scripts/11-export-prometheus-metrics.sh`
4. **Take screenshots** - For thesis figures
5. **Create charts** - From exported data

### **Comparison Workflow:**

1. **Baseline Scenario:**
   - Run tests without policies
   - Query Prometheus for baseline metrics
   - Note values

2. **NetworkPolicy Scenario:**
   - Apply NetworkPolicy
   - Run tests
   - Query Prometheus
   - Compare with baseline

3. **CiliumNetworkPolicy Scenario:**
   - Apply CiliumNetworkPolicy
   - Run tests
   - Query Prometheus
   - Compare with both previous scenarios

4. **Create Comparison Tables:**
   - Extract metrics from Prometheus
   - Calculate differences
   - Create tables showing eBPF vs iptables

---

## ✅ **Verification**

Run verification script:
```bash
./scripts/13-verify-prometheus.sh
```

This checks:
- Prometheus pods status
- Grafana pods status
- Services availability
- Cilium metrics scraping

---

## 🎯 **Next Steps**

1. **Access Prometheus** and verify Cilium metrics are visible
2. **Run comprehensive tests** - Metrics will be collected automatically
3. **Query metrics** for each scenario
4. **Export data** for analysis
5. **Create visualizations** for your thesis

**Everything is ready for data collection!**

