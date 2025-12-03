# Quick Fix Guide - Step by Step

## 🚀 **Quick Start: Fix Everything in 3 Steps**

### **Step 1: Fix Infrastructure** (5 minutes)
```bash
cd "/home/kali/Desktop/MSc Research Project/MSc-Research-Project-/testbed"
./scripts/07-fix-infrastructure.sh
```

This will:
- ✅ Install metrics-server
- ✅ Verify Cilium CLI is available
- ✅ Check DNS resolution

### **Step 2: Install Prometheus (Optional but Recommended)** (5-10 minutes)
```bash
./scripts/10-install-prometheus.sh
```

This will:
- ✅ Install Prometheus for metrics visualization
- ✅ Install Grafana for dashboards
- ✅ Configure Cilium metrics scraping
- ✅ Set up pre-configured dashboards

**Note:** Prometheus is automatically installed when running comprehensive tests, but you can install it separately first.

### **Step 3: Run Comprehensive Tests** (15-20 minutes)
```bash
./scripts/08-comprehensive-tests.sh
```

This will:
- ✅ Install Prometheus automatically (if not already installed)
- ✅ Run all tests for Baseline scenario
- ✅ Run all tests for NetworkPolicy scenario
- ✅ Run all tests for CiliumNetworkPolicy L7 scenario
- ✅ Collect all data automatically
- ✅ Export Prometheus metrics
- ✅ Save results in organized directories

### **Step 4: Run Statistical Tests** (Optional, 30-60 minutes)
```bash
# Run 5 iterations (default)
./scripts/09-statistical-runs.sh

# Or specify number of runs
./scripts/09-statistical-runs.sh 10
```

This will:
- ✅ Run multiple iterations for statistical significance
- ✅ Collect performance data across all scenarios
- ✅ Enable statistical analysis

---

## 📋 **What Was Fixed**

### **1. DNS Resolution Issue**
- ✅ Updated `connectivity.sh` to try multiple DNS methods
- ✅ Added fallback to service IP resolution

### **2. Latency Calculation Issue**
- ✅ Fixed performance test to properly extract HTTP response times
- ✅ Now calculates average latency from multiple requests

### **3. Ping Test Issue**
- ✅ Replaced ICMP ping with HTTP-based connectivity test
- ✅ ClusterIP services don't respond to ICMP, so use HTTP instead

### **4. Metrics-Server**
- ✅ Created script to install metrics-server automatically
- ✅ Added verification steps

### **5. Cilium CLI**
- ✅ Added check and PATH configuration
- ✅ Verifies CLI is functional

---

## 📊 **Results Structure**

After running the comprehensive tests, you'll have:

```
results/
├── baseline-YYYYMMDD-HHMMSS/
│   ├── connectivity.log
│   ├── attacks.log
│   ├── performance.log
│   ├── hubble-flows.json
│   ├── resources.txt
│   └── cilium-status.txt
├── networkpolicy-YYYYMMDD-HHMMSS/
│   └── (same structure)
└── cilium-l7-YYYYMMDD-HHMMSS/
    └── (same structure)
```

---

## 📊 **Access Prometheus & Grafana**

### **Prometheus UI:**
```bash
kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open: http://localhost:9090
```

### **Grafana UI:**
```bash
kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80
# Open: http://localhost:3000
# Username: admin
# Password: admin
```

### **Useful Prometheus Queries:**
- Cilium drops: `rate(cilium_drop_total[5m])`
- Cilium CPU: `rate(process_cpu_seconds_total{job="cilium"}[5m])`
- Network throughput: `rate(container_network_receive_bytes_total[5m])`
- Policy enforcement: `rate(cilium_policy_l7_total[5m])`

See `docs/PROMETHEUS_GUIDE.md` for more queries and details.

## 📈 **Next Steps: Calculate Metrics**

### **Manual Calculation**

1. **Attack Prevention Rate (APR):**
   ```bash
   # Count blocked attacks from attack logs
   grep "✓ SECURED\|BLOCKED" results/*/attacks.log | wc -l
   # Divide by total attacks
   ```

2. **Throughput:**
   ```bash
   # Extract from performance logs
   grep "Mbits/sec\|Gbits/sec" results/*/performance.log
   ```

3. **Latency:**
   ```bash
   # Extract from performance logs
   grep "Latency\|time_total" results/*/performance.log
   ```

### **Create Comparison Tables**

Use the data to create tables like:

| Scenario | Throughput | Latency | APR | FPR |
|----------|------------|---------|-----|-----|
| Baseline | X Mbps | Y ms | 0% | 0% |
| NetworkPolicy | X Mbps | Y ms | Z% | W% |
| CiliumNetworkPolicy | X Mbps | Y ms | Z% | W% |

---

## ✅ **Verification Checklist**

After running all scripts, verify:

- [ ] Metrics-server is installed and working
- [ ] Cilium CLI is available
- [ ] All test scripts run without errors
- [ ] Results collected for all 3 scenarios
- [ ] Data files are in results/ directory
- [ ] Can extract metrics from logs

---

## 🆘 **Troubleshooting**

### **If metrics-server fails:**
```bash
kubectl get pods -n kube-system -l k8s-app=metrics-server
kubectl logs -n kube-system -l k8s-app=metrics-server
```

### **If Cilium CLI not found:**
```bash
# Install it
./scripts/03-install-cilium.sh
# Or add to PATH
export PATH="${HOME}/.local/bin:${PATH}"
```

### **If tests fail:**
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check Cilium
cilium status
```

---

## 📝 **For Your Thesis**

After completing these steps, you'll have:

1. ✅ **Complete experimental data** for all scenarios
2. ✅ **Quantitative metrics** ready for analysis
3. ✅ **Statistical data** for significance testing
4. ✅ **Organized results** for easy reference

**You can now:**
- Extract metrics and create comparison tables
- Generate charts and visualizations
- Write the Results section of your thesis
- Perform statistical analysis

---

**Total Time Required: ~1-2 hours for complete data collection**

