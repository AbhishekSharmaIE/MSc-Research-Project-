#!/bin/bash
# Fix Infrastructure Issues
# Installs metrics-server, ensures Cilium CLI is available, fixes DNS

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Fixing Infrastructure Issues"
echo "=========================================="

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# 1. Install Metrics-Server
echo "[1/3] Installing metrics-server..."
if ! kubectl get deployment -n kube-system metrics-server &>/dev/null || ! kubectl top nodes &>/dev/null; then
    echo "Installing metrics-server with kind-compatible configuration..."
    "${PROJECT_ROOT}/scripts/install-metrics-server-kind.sh"
else
    echo "Metrics-server already installed and working"
fi

# Verify metrics-server
if kubectl top nodes &>/dev/null; then
    echo "✓ Metrics-server is working"
else
    echo "⚠ Warning: metrics-server may not be fully ready yet"
fi

# 2. Ensure Cilium CLI is available
echo "[2/3] Checking Cilium CLI..."
if ! command -v cilium &> /dev/null; then
    # Try to find it in common locations
    if [ -f "${HOME}/.local/bin/cilium" ]; then
        export PATH="${HOME}/.local/bin:${PATH}"
        echo "✓ Cilium CLI found in ~/.local/bin, added to PATH"
    elif [ -f "/usr/local/bin/cilium" ]; then
        echo "✓ Cilium CLI found in /usr/local/bin"
    else
        echo "✗ Cilium CLI not found. Please run ./scripts/03-install-cilium.sh"
        exit 1
    fi
else
    echo "✓ Cilium CLI is available"
fi

# Verify Cilium CLI works
if cilium version --client &>/dev/null; then
    echo "✓ Cilium CLI is functional"
    cilium version --client
else
    echo "⚠ Warning: Cilium CLI may not be working properly"
fi

# 3. Check DNS
echo "[3/3] Checking DNS resolution..."
COREDNS_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | wc -l)
if [ "$COREDNS_PODS" -gt 0 ]; then
    echo "✓ CoreDNS pods are running ($COREDNS_PODS pods)"
    
    # Test DNS from a pod
    if kubectl run -n tenant-a dns-test-$(date +%s) --image=busybox:1.36 --rm -i --restart=Never --timeout=10s -- \
        nslookup web-b.tenant-b.svc.cluster.local &>/dev/null; then
        echo "✓ DNS resolution is working"
    else
        echo "⚠ Warning: DNS test failed, but CoreDNS is running"
    fi
else
    echo "⚠ Warning: No CoreDNS pods found"
fi

echo ""
echo "=========================================="
echo "Infrastructure check complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Run comprehensive tests: ./scripts/08-comprehensive-tests.sh"
echo "2. Or run individual tests: ./tests/connectivity.sh"

