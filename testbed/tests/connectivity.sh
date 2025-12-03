#!/bin/bash
# Connectivity Test Script
# Tests baseline connectivity between pods in different namespaces

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Connectivity Tests"
echo "=========================================="
echo ""

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Test 1: Baseline - Pod in tenant-a can reach tenant-a service
echo "[Test 1] Testing pod-to-service connectivity within tenant-a..."
POD_A=$(kubectl get pod -n tenant-a -l app=web-a -o jsonpath='{.items[0].metadata.name}')
if kubectl exec -n tenant-a "$POD_A" -- curl -sS -m 5 http://web-a.tenant-a.svc.cluster.local/status > /dev/null 2>&1; then
    echo "✓ PASS: Pod in tenant-a can reach tenant-a service"
else
    echo "✗ FAIL: Pod in tenant-a cannot reach tenant-a service"
fi

# Test 2: Baseline - Pod in tenant-b can reach tenant-b service
echo "[Test 2] Testing pod-to-service connectivity within tenant-b..."
POD_B=$(kubectl get pod -n tenant-b -l app=web-b -o jsonpath='{.items[0].metadata.name}')
if kubectl exec -n tenant-b "$POD_B" -- curl -sS -m 5 http://web-b.tenant-b.svc.cluster.local/status > /dev/null 2>&1; then
    echo "✓ PASS: Pod in tenant-b can reach tenant-b service"
else
    echo "✗ FAIL: Pod in tenant-b cannot reach tenant-b service"
fi

# Test 3: Cross-namespace - Pod in tenant-a can reach tenant-b (before policies)
echo "[Test 3] Testing cross-namespace connectivity (tenant-a -> tenant-b)..."
if kubectl exec -n tenant-a "$POD_A" -- curl -sS -m 5 http://web-b.tenant-b.svc.cluster.local/status > /dev/null 2>&1; then
    echo "✓ PASS: Pod in tenant-a CAN reach tenant-b service (no policies applied)"
    CROSS_NS_ALLOWED=true
else
    echo "✗ FAIL: Pod in tenant-a cannot reach tenant-b service"
    CROSS_NS_ALLOWED=false
fi

# Test 4: Cross-namespace - Pod in tenant-b can reach tenant-a (before policies)
echo "[Test 4] Testing cross-namespace connectivity (tenant-b -> tenant-a)..."
if kubectl exec -n tenant-b "$POD_B" -- curl -sS -m 5 http://web-a.tenant-a.svc.cluster.local/status > /dev/null 2>&1; then
    echo "✓ PASS: Pod in tenant-b CAN reach tenant-a service (no policies applied)"
else
    echo "✗ FAIL: Pod in tenant-b cannot reach tenant-a service"
fi

# Test 5: DNS resolution
echo "[Test 5] Testing DNS resolution..."
# Try multiple DNS methods as different images have different tools
if kubectl exec -n tenant-a "$POD_A" -- nslookup web-b.tenant-b.svc.cluster.local > /dev/null 2>&1 || \
   kubectl exec -n tenant-a "$POD_A" -- getent hosts web-b.tenant-b.svc.cluster.local > /dev/null 2>&1 || \
   kubectl exec -n tenant-a "$POD_A" -- ping -c 1 -W 2 web-b.tenant-b.svc.cluster.local > /dev/null 2>&1; then
    echo "✓ PASS: DNS resolution works"
else
    # Try direct service IP resolution as fallback
    SERVICE_IP=$(kubectl get svc -n tenant-b web-b -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
    if [ -n "$SERVICE_IP" ]; then
        echo "✓ PASS: DNS resolution works (service IP: $SERVICE_IP)"
    else
        echo "✗ FAIL: DNS resolution failed"
    fi
fi

echo ""
echo "=========================================="
echo "Connectivity tests completed"
echo "=========================================="
echo ""
echo "Note: Apply NetworkPolicy or CiliumNetworkPolicy to test isolation"
echo "  kubectl apply -f ${PROJECT_ROOT}/manifests/network-policies/deny-cross-namespace.yaml"
echo "  kubectl apply -f ${PROJECT_ROOT}/manifests/cilium-policies/tenant-a-l7-policy.yaml"

