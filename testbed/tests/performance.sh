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
    START_TIME=$(date +%s%N)
    kubectl run -n tenant-b curl-latency --image=radial/busyboxplus:curl --rm -i --restart=Never -- \
        curl -sS -w "\nTime: %{time_total}s\n" -o /dev/null "$TARGET_SERVICE" 2>&1 || echo "curl test failed"
    END_TIME=$(date +%s%N)
    LATENCY=$(( (END_TIME - START_TIME) / 1000000 ))
    echo "Latency: ${LATENCY}ms"
fi

# Test 3: Resource utilization
echo ""
echo "[Test 3] Resource utilization measurement..."
echo "Collecting CPU and memory metrics..."

# Get Cilium agent resource usage
echo "Cilium agent resource usage:"
kubectl top pod -n kube-system -l k8s-app=cilium 2>/dev/null || echo "metrics-server not available, install with: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"

# Get workload resource usage
echo ""
echo "Workload resource usage:"
kubectl top pod -n tenant-a 2>/dev/null || echo "metrics-server not available"
kubectl top pod -n tenant-b 2>/dev/null || echo "metrics-server not available"

# Test 4: Concurrent connection test
echo ""
echo "[Test 4] Concurrent connection test..."
kubectl run -n tenant-b concurrent-test --image=radial/busyboxplus:curl --rm -i --restart=Never -- \
    sh -c "for i in \$(seq 1 10); do curl -sS -m 2 $TARGET_SERVICE > /dev/null && echo 'Request \$i: OK' || echo 'Request \$i: FAILED' & done; wait" 2>&1 || echo "Concurrent test failed"

# Test 5: Packet loss and jitter (if ping is available)
echo ""
echo "[Test 5] Network connectivity and packet loss..."
TARGET_IP=$(kubectl get svc -n tenant-a web-a -o jsonpath='{.spec.clusterIP}')
kubectl run -n tenant-b ping-test --image=radial/busyboxplus:curl --rm -i --restart=Never -- \
    ping -c 10 "$TARGET_IP" 2>&1 | tail -5 || echo "Ping test not available"

# Test 6: Cilium metrics
echo ""
echo "[Test 6] Cilium eBPF metrics..."
echo "Checking Cilium status and metrics..."
cilium status 2>/dev/null || echo "Cilium CLI not available"

# Get Cilium metrics from Prometheus endpoint (if available)
CILIUM_POD=$(kubectl get pod -n kube-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$CILIUM_POD" ]; then
    echo "Cilium pod: $CILIUM_POD"
    echo "Fetching metrics endpoint..."
    kubectl exec -n kube-system "$CILIUM_POD" -- wget -qO- http://localhost:9962/metrics 2>/dev/null | grep -E "cilium_policy|cilium_drop|cilium_forward" | head -10 || echo "Metrics endpoint not accessible"
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

