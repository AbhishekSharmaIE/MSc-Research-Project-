#!/bin/bash
# Attack Simulation Test Script
# Simulates various attack scenarios to test security policies

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Attack Simulation Tests"
echo "=========================================="
echo ""

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Ensure we have test pods
echo "Creating test pods for attack simulation..."
kubectl run -n tenant-b attacker-pod --image=radial/busyboxplus:curl --rm -i --restart=Never --command -- sleep 3600 &
ATTACKER_PID=$!
sleep 5

# Wait for pod to be ready
kubectl wait --for=condition=ready pod -n tenant-b attacker-pod --timeout=60s || true
ATTACKER_POD=$(kubectl get pod -n tenant-b -l run=attacker-pod -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$ATTACKER_POD" ]; then
    echo "Warning: Could not create attacker pod, using existing pod"
    ATTACKER_POD=$(kubectl get pod -n tenant-b -l app=web-b -o jsonpath='{.items[0].metadata.name}')
fi

TARGET_POD=$(kubectl get pod -n tenant-a -l app=web-a -o jsonpath='{.items[0].metadata.name}')

echo "Attacker pod: $ATTACKER_POD (tenant-b)"
echo "Target pod: $TARGET_POD (tenant-a)"
echo ""

# Attack 1: Cross-namespace unauthorized access attempt
echo "[Attack 1] Cross-namespace unauthorized access attempt..."
echo "Attempting to access tenant-a service from tenant-b pod..."
RESULT=$(kubectl exec -n tenant-b "$ATTACKER_POD" -- curl -sS -m 5 -w "%{http_code}" -o /dev/null http://web-a.tenant-a.svc.cluster.local/status 2>&1 || echo "BLOCKED")
if [[ "$RESULT" == "200" ]]; then
    echo "✗ VULNERABILITY: Cross-namespace access allowed (should be blocked by policy)"
else
    echo "✓ SECURED: Cross-namespace access blocked"
fi

# Attack 2: Unauthorized HTTP method (POST instead of GET)
echo "[Attack 2] Unauthorized HTTP method attack (POST to /status)..."
RESULT=$(kubectl exec -n tenant-b "$ATTACKER_POD" -- curl -sS -m 5 -X POST -w "%{http_code}" -o /dev/null http://web-a.tenant-a.svc.cluster.local/status 2>&1 || echo "BLOCKED")
if [[ "$RESULT" == "200" ]]; then
    echo "✗ VULNERABILITY: Unauthorized HTTP method allowed (L7 policy not enforced)"
else
    echo "✓ SECURED: Unauthorized HTTP method blocked (L7 policy working)"
fi

# Attack 3: Access to unauthorized path
echo "[Attack 3] Unauthorized path access (/api instead of /status)..."
RESULT=$(kubectl exec -n tenant-b "$ATTACKER_POD" -- curl -sS -m 5 -w "%{http_code}" -o /dev/null http://web-a.tenant-a.svc.cluster.local/api 2>&1 || echo "BLOCKED")
if [[ "$RESULT" == "200" ]]; then
    echo "✗ VULNERABILITY: Unauthorized path access allowed"
else
    echo "✓ SECURED: Unauthorized path access blocked"
fi

# Attack 4: Port scanning attempt (if we have a test pod with netcat)
echo "[Attack 4] Port scanning simulation..."
echo "Attempting to connect to non-HTTP port..."
RESULT=$(kubectl exec -n tenant-b "$ATTACKER_POD" -- nc -zv -w 2 web-a.tenant-a.svc.cluster.local 80 2>&1 || echo "BLOCKED")
if echo "$RESULT" | grep -q "succeeded\|open"; then
    echo "✗ INFO: Port 80 is accessible (expected for HTTP service)"
else
    echo "✓ INFO: Port connection blocked or failed"
fi

# Attack 5: Host network privilege escalation attempt
echo "[Attack 5] Host network privilege escalation attempt..."
echo "Attempting to deploy pod with hostNetwork=true..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: host-network-attacker
  namespace: tenant-b
spec:
  hostNetwork: true
  containers:
  - name: attacker
    image: radial/busyboxplus:curl
    command: ["sleep", "10"]
EOF

sleep 3
if kubectl get pod -n tenant-b host-network-attacker > /dev/null 2>&1; then
    echo "✗ WARNING: Pod with hostNetwork=true was created (check if policies prevent host access)"
    kubectl delete pod -n tenant-b host-network-attacker --ignore-not-found=true
else
    echo "✓ SECURED: Pod with hostNetwork=true creation blocked"
fi

# Attack 6: Service account token extraction simulation
echo "[Attack 6] Service account token access test..."
TOKEN=$(kubectl get secret -n tenant-b -o jsonpath='{.items[?(@.metadata.annotations.kubernetes\.io/service-account\.name=="tenant-user")].data.token}' 2>/dev/null | head -1)
if [ -n "$TOKEN" ]; then
    echo "✗ INFO: Service account token accessible (normal behavior, but verify RBAC prevents cross-namespace access)"
else
    echo "✓ INFO: Service account token not directly accessible"
fi

# Cleanup
if [ -n "$ATTACKER_PID" ]; then
    kill $ATTACKER_PID 2>/dev/null || true
fi
kubectl delete pod -n tenant-b attacker-pod --ignore-not-found=true

echo ""
echo "=========================================="
echo "Attack simulation tests completed"
echo "=========================================="
echo ""
echo "Check Hubble for flow logs:"
echo "  hubble observe --last 50 --from-pod $ATTACKER_POD"
echo ""
echo "Check Cilium monitor for policy decisions:"
echo "  cilium monitor --json | jq 'select(.type==\"drop\" or .type==\"policy\")'"

