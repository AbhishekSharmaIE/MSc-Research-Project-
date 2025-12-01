# Testing Guide

This guide describes the test scenarios and procedures for evaluating eBPF/Cilium security in multi-tenant Kubernetes.

## Test Scenarios Overview

1. **Baseline Connectivity** - Verify default pod-to-pod communication
2. **NetworkPolicy Enforcement** - Test traditional Kubernetes NetworkPolicy
3. **CiliumNetworkPolicy L7** - Test eBPF-based L7 enforcement
4. **Cross-Tenant Attacks** - Simulate unauthorized access attempts
5. **Performance Benchmarking** - Compare eBPF vs traditional approaches

## Test Execution

### Quick Test Run

Run all tests sequentially:

```bash
./scripts/06-run-tests.sh
```

### Individual Test Scripts

Run tests individually:

```bash
# Connectivity tests
./tests/connectivity.sh

# Attack simulations
./tests/attacks.sh

# Performance benchmarks
./tests/performance.sh
```

## Test Scenarios

### Scenario 1: Baseline Connectivity (No Policies)

**Objective**: Verify default Kubernetes networking behavior

**Steps**:
1. Deploy workloads (already done in setup)
2. Run connectivity test:
   ```bash
   ./tests/connectivity.sh
   ```

**Expected Results**:
- Pods within same namespace can communicate ✓
- Pods across namespaces can communicate ✓ (default behavior)
- DNS resolution works ✓

**Documentation**:
- Record connectivity matrix
- Note latency measurements
- Capture Hubble flows: `hubble observe --last 50 --output json > baseline-flows.json`

### Scenario 2: Traditional NetworkPolicy

**Objective**: Test Kubernetes NetworkPolicy isolation

**Steps**:
1. Apply NetworkPolicy:
   ```bash
   kubectl apply -f manifests/network-policies/deny-cross-namespace.yaml
   ```

2. Test connectivity:
   ```bash
   # From tenant-b, try to reach tenant-a
   kubectl run -n tenant-b test-pod --image=radial/busyboxplus:curl --rm -i --restart=Never -- \
     curl -sS http://web-a.tenant-a.svc.cluster.local/status
   ```

**Expected Results**:
- Cross-namespace traffic blocked ✓
- Same-namespace traffic allowed ✓

**Verification**:
```bash
kubectl get networkpolicy -n tenant-a
hubble observe --last 20 --verdict DROPPED
```

### Scenario 3: CiliumNetworkPolicy L7 Enforcement

**Objective**: Test eBPF-based L7 (HTTP) policy enforcement

**Steps**:
1. Remove NetworkPolicy (if applied):
   ```bash
   kubectl delete networkpolicy -n tenant-a deny-cross-ns
   ```

2. Apply CiliumNetworkPolicy:
   ```bash
   kubectl apply -f manifests/cilium-policies/tenant-a-l7-policy.yaml
   ```

3. Test allowed request (GET /status):
   ```bash
   kubectl run -n tenant-a test-pod --image=radial/busyboxplus:curl --rm -i --restart=Never -- \
     curl -sS -X GET http://web-a.tenant-a.svc.cluster.local/status
   ```

4. Test blocked request (POST /status):
   ```bash
   kubectl run -n tenant-b test-pod --image=radial/busyboxplus:curl --rm -i --restart=Never -- \
     curl -sS -X POST http://web-a.tenant-a.svc.cluster.local/status
   ```

5. Test blocked path (/api):
   ```bash
   kubectl run -n tenant-b test-pod --image=radial/busyboxplus:curl --rm -i --restart=Never -- \
     curl -sS http://web-a.tenant-a.svc.cluster.local/api
   ```

**Expected Results**:
- GET /status from same namespace: ALLOWED ✓
- POST /status: BLOCKED ✓
- GET /api: BLOCKED ✓
- Cross-namespace GET /status: BLOCKED ✓

**Verification**:
```bash
# Check CiliumNetworkPolicy
kubectl get cnp -n tenant-a

# View L7 flows in Hubble
hubble observe --last 50 --type l7

# Check policy decisions
cilium monitor --json | jq 'select(.type=="policy")'
```

### Scenario 4: Cross-Tenant Attack Simulation

**Objective**: Simulate real-world attack scenarios

**Run attack tests**:
```bash
./tests/attacks.sh
```

**Attack Types**:

1. **Cross-namespace unauthorized access**
   - Attempt to access tenant-a from tenant-b
   - Expected: Blocked by policy

2. **Unauthorized HTTP method**
   - POST request to GET-only endpoint
   - Expected: Blocked by L7 policy

3. **Unauthorized path access**
   - Access to /api instead of /status
   - Expected: Blocked by L7 policy

4. **Host network privilege escalation**
   - Deploy pod with hostNetwork=true
   - Expected: Check if policies prevent host access

5. **Service account token access**
   - Attempt to use service account from different namespace
   - Expected: Blocked by RBAC

**Documentation**:
- Record attack success/failure
- Capture Hubble flows for each attack
- Note policy enforcement points

### Scenario 5: Performance Benchmarking

**Objective**: Measure performance overhead of eBPF policies

**Run performance tests**:
```bash
./tests/performance.sh
```

**Metrics to Collect**:

1. **Network Throughput**
   - Use iperf3 between pods
   - Measure: Mbits/sec
   - Compare: With/without policies

2. **HTTP Latency**
   - Use hey/wrk for load testing
   - Measure: p50, p95, p99 latency
   - Compare: Baseline vs with policies

3. **Resource Utilization**
   - CPU usage: `kubectl top pod -n kube-system -l k8s-app=cilium`
   - Memory usage: `kubectl top pod -n kube-system -l k8s-app=cilium`
   - Compare: Cilium vs traditional CNI

4. **Concurrent Connections**
   - Test: 10, 50, 100 concurrent connections
   - Measure: Success rate, response time

**Data Collection**:

```bash
# Collect metrics over time
watch -n 5 'kubectl top pod -n kube-system -l k8s-app=cilium' > cilium-metrics.log

# Export Hubble flows
hubble observe --last 1000 --output json > performance-flows.json

# Export Cilium metrics
kubectl exec -n kube-system $(kubectl get pod -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}') -- \
  wget -qO- http://localhost:9962/metrics > cilium-prometheus-metrics.txt
```

## Test Results Documentation

### Results Directory Structure

```
results/
├── baseline-YYYYMMDD-HHMMSS/
│   ├── connectivity.log
│   ├── hubble-flows.json
│   └── metrics.txt
├── networkpolicy-YYYYMMDD-HHMMSS/
│   ├── connectivity.log
│   ├── hubble-flows.json
│   └── policy-enforcement.log
├── cilium-l7-YYYYMMDD-HHMMSS/
│   ├── l7-tests.log
│   ├── hubble-flows.json
│   └── policy-decisions.log
├── attacks-YYYYMMDD-HHMMSS/
│   ├── attack-results.log
│   ├── hubble-flows.json
│   └── security-events.log
└── performance-YYYYMMDD-HHMMSS/
    ├── throughput-results.txt
    ├── latency-results.txt
    ├── resource-usage.txt
    └── cilium-metrics.txt
```

### Analysis Checklist

For each test scenario, document:

- [ ] Test conditions (policies applied, cluster state)
- [ ] Connectivity matrix (who can talk to whom)
- [ ] Policy enforcement results (allowed/blocked)
- [ ] Performance metrics (throughput, latency, CPU, memory)
- [ ] Hubble flow logs
- [ ] Cilium monitor output
- [ ] Screenshots (Hubble UI, Grafana dashboards)
- [ ] Anomalies or unexpected behavior

## Comparison Testing

### Baseline: No Policies
```bash
# Ensure no policies are applied
kubectl delete networkpolicy --all --all-namespaces
kubectl delete cnp --all --all-namespaces

# Run tests
./tests/connectivity.sh > results/baseline-connectivity.log
./tests/performance.sh > results/baseline-performance.log
```

### Traditional: NetworkPolicy Only
```bash
# Apply NetworkPolicy
kubectl apply -f manifests/network-policies/deny-cross-namespace.yaml

# Run tests
./tests/connectivity.sh > results/networkpolicy-connectivity.log
./tests/performance.sh > results/networkpolicy-performance.log
```

### Advanced: CiliumNetworkPolicy L7
```bash
# Remove NetworkPolicy, apply CiliumNetworkPolicy
kubectl delete networkpolicy -n tenant-a deny-cross-ns
kubectl apply -f manifests/cilium-policies/tenant-a-l7-policy.yaml

# Run tests
./tests/connectivity.sh > results/cilium-l7-connectivity.log
./tests/attacks.sh > results/cilium-l7-attacks.log
./tests/performance.sh > results/cilium-l7-performance.log
```

## Troubleshooting Tests

### Connectivity Tests Fail

**Check**:
- Pods are running: `kubectl get pods --all-namespaces`
- Services exist: `kubectl get svc --all-namespaces`
- DNS works: `kubectl run -it --rm debug --image=busybox -- nslookup kubernetes.default`

### Attack Tests Don't Show Blocking

**Check**:
- Policies are applied: `kubectl get cnp --all-namespaces`
- Cilium is enforcing: `cilium status`
- Hubble shows flows: `hubble observe --last 20`

### Performance Tests Fail

**Check**:
- Sufficient resources: `kubectl top nodes`
- Test pods can be created: `kubectl get pods`
- Network connectivity: `kubectl exec -it <pod> -- ping <target>`

## Next Steps

After completing tests:

1. **Analyze Results**: Compare metrics across scenarios
2. **Generate Report**: Document findings in research paper format
3. **Visualize Data**: Create graphs from collected metrics
4. **Document Findings**: Update presentation with results

