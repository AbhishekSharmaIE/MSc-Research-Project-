#!/bin/bash
# Performance Benchmarking Script
# Measures network throughput, latency, and resource utilization

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Performance Benchmarking Tests"
echo "=========================================="
echo ""

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Test 1: Network throughput with iperf3
echo "[Test 1] Network throughput test (iperf3)..."
echo "Deploying iperf3 server in tenant-a..."
kubectl run -n tenant-a iperf3-server --image=networkstatic/iperf3 --command -- iperf3 -s --port 5201 &
sleep 5
kubectl wait --for=condition=ready pod -n tenant-a iperf3-server --timeout=60s || true

SERVER_POD=$(kubectl get pod -n tenant-a -l run=iperf3-server -o jsonpath='{.items[0].metadata.name}')
SERVER_IP=$(kubectl get pod -n tenant-a "$SERVER_POD" -o jsonpath='{.status.podIP}')

echo "Deploying iperf3 client in tenant-b..."
kubectl run -n tenant-b iperf3-client --image=networkstatic/iperf3 --rm -i --restart=Never --command -- iperf3 -c "$SERVER_IP" -t 10 -f m 2>&1 | tee /tmp/iperf3-result.txt || echo "iperf3 test failed"

# Extract throughput from result
if [ -f /tmp/iperf3-result.txt ]; then
    THROUGHPUT=$(grep -i "sender\|receiver" /tmp/iperf3-result.txt | tail -1 | awk '{print $7}')
    echo "Throughput: ${THROUGHPUT} Mbits/sec"
fi

# Cleanup iperf3
kubectl delete pod -n tenant-a iperf3-server --ignore-not-found=true
kubectl delete pod -n tenant-b iperf3-client --ignore-not-found=true

# Test 2: HTTP latency with hey
echo ""
echo "[Test 2] HTTP latency test (hey/wrk)..."
TARGET_SERVICE="http://web-a.tenant-a.svc.cluster.local/status"

# Check if hey is available, otherwise use curl
if command -v hey &> /dev/null; then
    echo "Running hey load test..."
    kubectl run -n tenant-b hey-test --image=rakyll/hey --rm -i --restart=Never -- \
        -z 10s -q 10 -c 5 "$TARGET_SERVICE" 2>&1 | tee /tmp/hey-result.txt || echo "hey test failed"
else
    echo "hey not available, using curl for basic latency test..."
    # Run multiple requests and extract timing from curl output
    LATENCY_OUTPUT=$(kubectl run -n tenant-b curl-latency --image=radial/busyboxplus:curl --rm -i --restart=Never -- \
        sh -c "for i in \$(seq 1 10); do curl -sS -w '%{time_total}\n' -o /dev/null '$TARGET_SERVICE' 2>&1; done" 2>&1 | grep -E '^[0-9]+\.[0-9]+$' || echo "")
    
    if [ -n "$LATENCY_OUTPUT" ]; then
        # Calculate average latency
        LATENCY_MS=$(echo "$LATENCY_OUTPUT" | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", (sum/count)*1000; else print "N/A"}' 2>/dev/null || echo "N/A")
        echo "Average Latency: ${LATENCY_MS}ms (from 10 requests)"
    else
        echo "Latency: Could not measure (test may have failed)"
    fi
fi

# Test 3: Resource utilization
echo ""
echo "[Test 3] Resource utilization measurement..."
echo "Collecting CPU and memory metrics..."

# Check and install metrics-server if needed
if ! kubectl get deployment -n kube-system metrics-server &>/dev/null || ! kubectl top nodes &>/dev/null; then
    echo "Installing metrics-server..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
    "${PROJECT_ROOT}/scripts/install-metrics-server-kind.sh" 2>/dev/null || true
fi

# Get Cilium agent resource usage
echo "Cilium agent resource usage:"
if kubectl top pod -n kube-system -l k8s-app=cilium 2>/dev/null; then
    kubectl top pod -n kube-system -l k8s-app=cilium
else
    echo "⚠ Warning: metrics-server not ready yet, resource metrics unavailable"
fi

# Get workload resource usage
echo ""
echo "Workload resource usage:"
if kubectl top pod -n tenant-a 2>/dev/null; then
    kubectl top pod -n tenant-a
else
    echo "⚠ Warning: metrics-server not ready yet for tenant-a"
fi
if kubectl top pod -n tenant-b 2>/dev/null; then
    kubectl top pod -n tenant-b
else
    echo "⚠ Warning: metrics-server not ready yet for tenant-b"
fi

# Test 4: Concurrent connection test
echo ""
echo "[Test 4] Concurrent connection test..."
kubectl run -n tenant-b concurrent-test --image=radial/busyboxplus:curl --rm -i --restart=Never -- \
    sh -c "for i in \$(seq 1 10); do curl -sS -m 2 $TARGET_SERVICE > /dev/null && echo 'Request \$i: OK' || echo 'Request \$i: FAILED' & done; wait" 2>&1 || echo "Concurrent test failed"

# Test 5: Network connectivity (HTTP-based, as ClusterIP doesn't respond to ICMP)
echo ""
echo "[Test 5] Network connectivity test (HTTP-based)..."
TARGET_SERVICE="http://web-a.tenant-a.svc.cluster.local/status"
SUCCESS_COUNT=0
TOTAL_REQUESTS=10

for i in $(seq 1 $TOTAL_REQUESTS); do
    if kubectl run -n tenant-b connectivity-test-$i --image=radial/busyboxplus:curl --rm -i --restart=Never --timeout=5s -- \
        curl -sS -m 2 -o /dev/null -w "%{http_code}" "$TARGET_SERVICE" 2>&1 | grep -q "200"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    fi
    sleep 0.5
done

SUCCESS_RATE=$(( (SUCCESS_COUNT * 100) / TOTAL_REQUESTS ))
echo "Connectivity: ${SUCCESS_COUNT}/${TOTAL_REQUESTS} successful (${SUCCESS_RATE}% success rate)"

# Test 6: Cilium metrics
echo ""
echo "[Test 6] Cilium eBPF metrics..."
echo "Checking Cilium status and metrics..."

# Check for Cilium CLI
if ! command -v cilium &> /dev/null; then
    # Try to find it in common locations
    if [ -f "${HOME}/.local/bin/cilium" ]; then
        export PATH="${HOME}/.local/bin:${PATH}"
    fi
fi

if command -v cilium &> /dev/null; then
    echo "Cilium CLI status:"
    cilium status 2>/dev/null || echo "⚠ Warning: Cilium CLI available but status check failed"
else
    echo "⚠ Warning: Cilium CLI not available"
    echo "  Install with: ./scripts/03-install-cilium.sh"
    echo "  Or add to PATH: export PATH=\"\${HOME}/.local/bin:\${PATH}\""
fi

# Get Cilium metrics from Prometheus endpoint (if available)
CILIUM_POD=$(kubectl get pod -n kube-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$CILIUM_POD" ]; then
    echo ""
    echo "Cilium pod: $CILIUM_POD"
    echo "Fetching metrics endpoint..."
    METRICS=$(kubectl exec -n kube-system "$CILIUM_POD" -- wget -qO- http://localhost:9962/metrics 2>/dev/null | grep -E "cilium_policy|cilium_drop|cilium_forward" | head -10)
    if [ -n "$METRICS" ]; then
        echo "$METRICS"
    else
        echo "⚠ Metrics endpoint not accessible or no relevant metrics found"
    fi
else
    echo "⚠ Warning: Cilium pod not found"
fi

echo ""
echo "=========================================="
echo "Performance benchmarking completed"
echo "=========================================="
echo ""
echo "For detailed metrics, install Prometheus:"
echo "  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
echo "  helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace"
echo ""
echo "View Hubble flows for network performance:"
echo "  hubble observe --last 100 --output json | jq 'select(.Type==\"L7\")'"

