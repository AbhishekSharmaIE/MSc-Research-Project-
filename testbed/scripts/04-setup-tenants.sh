#!/bin/bash
# Setup Multi-Tenant Environment
# Creates namespaces, RBAC, and resource quotas for tenants

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Setting up Multi-Tenant Environment"
echo "=========================================="

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Create namespaces
echo "[1/4] Creating tenant namespaces..."
kubectl create namespace tenant-a --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace tenant-b --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace platform-tools --dry-run=client -o yaml | kubectl apply -f -

# Label namespaces for network policies
kubectl label namespace tenant-a kube-namespace=tenant-a --overwrite
kubectl label namespace tenant-b kube-namespace=tenant-b --overwrite

# Apply RBAC
echo "[2/4] Applying RBAC policies..."
kubectl apply -f "${PROJECT_ROOT}/manifests/rbac/tenant-a-rbac.yaml"
kubectl apply -f "${PROJECT_ROOT}/manifests/rbac/tenant-b-rbac.yaml"

# Apply Resource Quotas
echo "[3/4] Applying resource quotas..."
kubectl apply -f "${PROJECT_ROOT}/manifests/rbac/tenant-a-quota.yaml"
kubectl apply -f "${PROJECT_ROOT}/manifests/rbac/tenant-b-quota.yaml"

# Display status
echo "[4/4] Verifying setup..."
echo ""
echo "=========================================="
echo "Multi-tenant environment setup complete!"
echo "=========================================="
echo ""
kubectl get namespaces
echo ""
kubectl get roles,rolebindings -n tenant-a
kubectl get roles,rolebindings -n tenant-b
kubectl get resourcequota -n tenant-a
kubectl get resourcequota -n tenant-b
echo ""
echo "Next step: Run ./scripts/05-deploy-workloads.sh"

