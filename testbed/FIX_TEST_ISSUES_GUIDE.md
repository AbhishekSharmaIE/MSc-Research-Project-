# Step-by-Step Guide: Fixing Test Issues & Completing Experimental Work

This guide provides actionable steps to fix all test errors and complete your experimental data collection for the MSc thesis.

---

## 🔧 **STEP 1: Fix Infrastructure Issues**

### **1.1 Install Metrics-Server**

```bash
cd "/home/kali/Desktop/MSc Research Project/MSc-Research-Project-/testbed"

# Install metrics-server
kubectl apply -f manifests/monitoring/metrics-server.yaml

# Wait for it to be ready
kubectl wait --for=condition=ready pod -n kube-system -l k8s-app=metrics-server --timeout=120s

# Verify it's working
kubectl top nodes
kubectl top pods -n tenant-a
```

### **1.2 Ensure Cilium CLI is Available**

```bash
# Check if Cilium CLI is installed
which cilium

# If not found, add to PATH (from ~/.local/bin)
export PATH="${HOME}/.local/bin:${PATH}"

# Or install to /usr/local/bin (requires sudo)
# The script 03-install-cilium.sh should have done this, but verify:
cilium version --client
```

### **1.3 Fix DNS Resolution Issue**

The DNS test is failing. Let's check and fix:

```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check DNS service
kubectl get svc -n kube-system kube-dns

# Test DNS from a pod
kubectl run -n tenant-a dns-test --image=busybox:1.36 --rm -i --restart=Never -- \
  nslookup web-b.tenant-b.svc.cluster.local

# If DNS works from pod but test fails, the issue is in the test script
```

---

## 🔧 **STEP 2: Fix Test Scripts**

### **2.1 Fix Connectivity Test (DNS Issue)**

The DNS test in `connectivity.sh` might be using wrong command. Update it:

```bash
# Edit the test to use proper DNS command
# The issue is likely that nslookup might not be available in the image
# Use 'getent hosts' or 'ping -c 1' instead
```

### **2.2 Fix Performance Test (Latency Calculation)**

The latency calculation in `performance.sh` is wrong (showing 2084ms when it should be ~1ms). Fix the timing:

```bash
# The issue is that the script is measuring script execution time, not HTTP latency
# Need to parse curl output properly
```

### **2.3 Fix Ping Test**

Ping is failing because ClusterIP might not respond to ICMP. Use HTTP instead:

```bash
# Replace ping test with HTTP connectivity test
```

---

## 📊 **STEP 3: Create Enhanced Test Scripts**

### **3.1 Create Comprehensive Test Runner**

Create a script that runs all scenarios systematically:

```bash
# This will be created as: scripts/07-comprehensive-tests.sh
```

### **3.2 Create Data Collection Script**

Create a script that collects and formats all metrics:

```bash
# This will be created as: scripts/08-collect-metrics.sh
```

---

## 🧪 **STEP 4: Run Tests Across All Scenarios**

### **Scenario A: Baseline (No Policies)**

```bash
# 1. Ensure no policies are applied
kubectl delete networkpolicy --all --all-namespaces
kubectl delete cnp --all --all-namespaces

# 2. Run connectivity tests
./tests/connectivity.sh > results/baseline-connectivity-$(date +%Y%m%d-%H%M%S).log

# 3. Run performance tests
./tests/performance.sh > results/baseline-performance-$(date +%Y%m%d-%H%M%S).log

# 4. Run attack tests (should show vulnerabilities)
./tests/attacks.sh > results/baseline-attacks-$(date +%Y%m%d-%H%M%S).log

# 5. Collect Hubble flows
hubble observe --last 1000 --output json > results/baseline-hubble-$(date +%Y%m%d-%H%M%S).json
```

### **Scenario B: Traditional NetworkPolicy**

```bash
# 1. Apply NetworkPolicy
kubectl apply -f manifests/network-policies/deny-cross-namespace.yaml

# 2. Wait for policy to be active
sleep 10

# 3. Run all tests
./tests/connectivity.sh > results/networkpolicy-connectivity-$(date +%Y%m%d-%H%M%S).log
./tests/performance.sh > results/networkpolicy-performance-$(date +%Y%m%d-%H%M%S).log
./tests/attacks.sh > results/networkpolicy-attacks-$(date +%Y%m%d-%H%M%S).log
hubble observe --last 1000 --output json > results/networkpolicy-hubble-$(date +%Y%m%d-%H%M%S).json

# 4. Collect resource metrics
kubectl top pods --all-namespaces > results/networkpolicy-resources-$(date +%Y%m%d-%H%M%S).txt
```

### **Scenario C: CiliumNetworkPolicy L7**

```bash
# 1. Remove NetworkPolicy
kubectl delete networkpolicy -n tenant-a deny-cross-ns

# 2. Apply CiliumNetworkPolicy
kubectl apply -f manifests/cilium-policies/tenant-a-l7-policy.yaml
kubectl apply -f manifests/cilium-policies/tenant-b-l7-policy.yaml

# 3. Wait for policies to be active
sleep 10

# 4. Run all tests
./tests/connectivity.sh > results/cilium-l7-connectivity-$(date +%Y%m%d-%H%M%S).log
./tests/performance.sh > results/cilium-l7-performance-$(date +%Y%m%d-%H%M%S).log
./tests/attacks.sh > results/cilium-l7-attacks-$(date +%Y%m%d-%H%M%S).log
hubble observe --last 1000 --output json > results/cilium-l7-hubble-$(date +%Y%m%d-%H%M%S).json

# 5. Collect resource metrics
kubectl top pods --all-namespaces > results/cilium-l7-resources-$(date +%Y%m%d-%H%M%S).txt
```

### **Scenario D: Multiple Test Runs (Statistical Significance)**

```bash
# Run each scenario 5-10 times for statistical validation
for i in {1..5}; do
  echo "=== Run $i ==="
  
  # Baseline
  ./tests/performance.sh >> results/baseline-performance-run$i-$(date +%Y%m%d-%H%M%S).log
  
  # NetworkPolicy
  kubectl apply -f manifests/network-policies/deny-cross-namespace.yaml
  sleep 5
  ./tests/performance.sh >> results/networkpolicy-performance-run$i-$(date +%Y%m%d-%H%M%S).log
  kubectl delete networkpolicy -n tenant-a deny-cross-ns
  
  # CiliumNetworkPolicy
  kubectl apply -f manifests/cilium-policies/tenant-a-l7-policy.yaml
  sleep 5
  ./tests/performance.sh >> results/cilium-l7-performance-run$i-$(date +%Y%m%d-%H%M%S).log
  kubectl delete cnp -n tenant-a tenant-a-l7-policy
  
  sleep 30  # Wait between runs
done
```

---

## 📈 **STEP 5: Calculate Quantitative Metrics**

### **5.1 Create Metrics Calculation Script**

Create a Python script to parse logs and calculate metrics:

```python
# This will be created as: scripts/calculate-metrics.py
# It will:
# - Parse attack logs to calculate APR, FPR, DR
# - Parse performance logs to extract throughput, latency
# - Parse resource logs to get CPU/memory usage
# - Generate comparison tables
```

### **5.2 Manual Calculation (If Script Not Available)**

**Attack Prevention Rate (APR):**
```
APR = (Number of Attacks Blocked / Total Attack Attempts) × 100

From attack logs:
- Count lines with "✓ SECURED" or "BLOCKED"
- Count lines with "✗ VULNERABILITY" or "allowed"
- Calculate: (Blocked / Total) × 100
```

**False Positive Rate (FPR):**
```
FPR = (Legitimate Requests Blocked / Total Legitimate Requests) × 100

Test with legitimate traffic and count blocks
```

**Throughput:**
```
From performance logs, extract iperf3 results:
- Look for "Mbits/sec" or "Gbits/sec"
- Record average throughput
```

**Latency:**
```
From performance logs:
- Extract HTTP response times
- Calculate p50, p95, p99 if multiple measurements
```

---

## 📊 **STEP 6: Create Comparative Tables**

### **6.1 Security Effectiveness Table**

| Metric | Baseline | NetworkPolicy | CiliumNetworkPolicy L7 |
|--------|----------|--------------|------------------------|
| Attack Prevention Rate | 0% | [X]% | [Y]% |
| False Positive Rate | 0% | [X]% | [Y]% |
| Detection Rate | 0% | [X]% | [Y]% |
| Cross-namespace blocked | ❌ | ✅ | ✅ |
| L7 attacks blocked | ❌ | ❌ | ✅ |

### **6.2 Performance Comparison Table**

| Metric | Baseline | NetworkPolicy | CiliumNetworkPolicy L7 | Overhead |
|--------|----------|--------------|------------------------|----------|
| Throughput (Mbps) | [X] | [Y] | [Z] | [%] |
| Latency p95 (ms) | [X] | [Y] | [Z] | [%] |
| CPU Usage (%) | [X] | [Y] | [Z] | [%] |
| Memory (MB) | [X] | [Y] | [Z] | [%] |

### **6.3 eBPF vs iptables Comparison**

| Metric | iptables (NetworkPolicy) | eBPF (CiliumNetworkPolicy) | Improvement |
|--------|--------------------------|----------------------------|-------------|
| Throughput | [X] Mbps | [Y] Mbps | [Z]% |
| Latency | [X] ms | [Y] ms | [Z]% |
| CPU Overhead | [X]% | [Y]% | [Z]% |
| L7 Capability | ❌ | ✅ | N/A |

---

## 📈 **STEP 7: Generate Visualizations**

### **7.1 Create Charts**

Use Python (matplotlib) or Excel/Google Sheets:

1. **Bar Chart**: Attack Prevention Rates
2. **Line Chart**: Throughput Comparison
3. **Line Chart**: Latency Comparison
4. **Bar Chart**: Resource Utilization
5. **Comparison Chart**: eBPF vs iptables

### **7.2 Example Python Script**

```python
import matplotlib.pyplot as plt
import pandas as pd

# Load data from results
data = {
    'Scenario': ['Baseline', 'NetworkPolicy', 'CiliumNetworkPolicy'],
    'Throughput': [24063, 23500, 23800],  # Replace with actual data
    'Latency': [1.0, 1.2, 1.5],  # Replace with actual data
}

df = pd.DataFrame(data)

# Create charts
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

ax1.bar(df['Scenario'], df['Throughput'])
ax1.set_ylabel('Throughput (Mbps)')
ax1.set_title('Network Throughput Comparison')

ax2.bar(df['Scenario'], df['Latency'])
ax2.set_ylabel('Latency (ms)')
ax2.set_title('Latency Comparison')

plt.tight_layout()
plt.savefig('results/comparison-charts.png')
```

---

## ✅ **STEP 8: Verification Checklist**

After completing all steps, verify:

- [ ] Metrics-server installed and working
- [ ] Cilium CLI available
- [ ] DNS resolution working
- [ ] All test scripts run without errors
- [ ] Data collected for all 3 scenarios:
  - [ ] Baseline (no policies)
  - [ ] Traditional NetworkPolicy
  - [ ] CiliumNetworkPolicy L7
- [ ] Multiple test runs completed (5+ runs)
- [ ] All metrics calculated:
  - [ ] Attack Prevention Rate (APR)
  - [ ] False Positive Rate (FPR)
  - [ ] Detection Rate (DR)
  - [ ] Throughput measurements
  - [ ] Latency measurements
  - [ ] CPU utilization
  - [ ] Memory utilization
- [ ] Comparative tables created
- [ ] Visualizations generated
- [ ] Results documented in thesis format

---

## 🚀 **Quick Start: Run Everything**

I'll create automated scripts to do all of this. The next step is to create the fix scripts.

