#!/bin/bash
# Creating Kind Multi-Node Cluster
# this script a 3-node cluster (1 control-plane, 2 workers) for multi-tenant testing

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Creating Kind Multi-Node Cluster"
echo "=========================================="

# Check if cluster already exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Cluster '${CLUSTER_NAME}' already exists."
    read -p "Do you want to delete it and create a new one? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing cluster..."
        kind delete cluster --name "${CLUSTER_NAME}"
    else
        echo "Using existing cluster."
        exit 0
    fi
fi

# Create cluster using config
echo "Creating cluster '${CLUSTER_NAME}' with 3 nodes (1 control-plane, 2 workers)..."
kind create cluster \
    --name "${CLUSTER_NAME}" \
    --config "${PROJECT_ROOT}/manifests/cluster/kind-multi.yaml"

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl cluster-info --context "kind-${CLUSTER_NAME}"
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Display cluster info
echo ""
echo "=========================================="
echo "Cluster created successfully!"
echo "=========================================="
kubectl get nodes -o wide
echo ""
echo "Cluster context: kind-${CLUSTER_NAME}"
echo ""
echo "Next step: Run ./scripts/03-install-cilium.sh"

