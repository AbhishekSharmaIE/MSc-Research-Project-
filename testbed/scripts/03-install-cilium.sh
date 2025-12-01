#!/bin/bash
# Install Cilium and Hubble
# Installs Cilium as CNI and enables Hubble observability

set -e

CLUSTER_NAME="cilium-multitenant"

echo "=========================================="
echo "Installing Cilium and Hubble"
echo "=========================================="

# Check if cluster exists
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Error: Cluster '${CLUSTER_NAME}' not found."
    echo "Please run ./scripts/02-create-cluster.sh first"
    exit 1
fi

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Install Cilium
echo "[1/3] Installing Cilium..."
cilium install --wait

# Wait for Cilium to be ready
echo "[2/3] Waiting for Cilium to be ready..."
cilium status --wait

# Enable Hubble with UI
echo "[3/3] Enabling Hubble observability..."
cilium hubble enable --ui

# Wait for Hubble pods
echo "Waiting for Hubble pods to be ready..."
kubectl -n kube-system wait --for=condition=ready pod -l k8s-app=hubble-relay --timeout=300s || true
kubectl -n kube-system wait --for=condition=ready pod -l k8s-app=hubble-ui --timeout=300s || true

# Display status
echo ""
echo "=========================================="
echo "Cilium and Hubble installation complete!"
echo "=========================================="
echo ""
cilium status
echo ""
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl -n kube-system get pods -l k8s-app=hubble
echo ""
echo "To access Hubble UI, run:"
echo "  kubectl -n kube-system port-forward svc/hubble-ui 12000:80"
echo "  Then open http://localhost:12000 in your browser"
echo ""
echo "Next step: Run ./scripts/04-setup-tenants.sh"

