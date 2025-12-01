#!/bin/bash
# Deploy Sample Workloads
# Deploys nginx and test pods for each tenant

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Deploying Sample Workloads"
echo "=========================================="

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Deploy tenant-a workloads
echo "[1/3] Deploying tenant-a workloads..."
kubectl apply -f "${PROJECT_ROOT}/manifests/workloads/tenant-a-deployment.yaml"
kubectl apply -f "${PROJECT_ROOT}/manifests/workloads/tenant-a-service.yaml"

# Deploy tenant-b workloads
echo "[2/3] Deploying tenant-b workloads..."
kubectl apply -f "${PROJECT_ROOT}/manifests/workloads/tenant-b-deployment.yaml"
kubectl apply -f "${PROJECT_ROOT}/manifests/workloads/tenant-b-service.yaml"

# Wait for pods to be ready
echo "[3/3] Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=web-a -n tenant-a --timeout=300s
kubectl wait --for=condition=ready pod -l app=web-b -n tenant-b --timeout=300s

# Display status
echo ""
echo "=========================================="
echo "Workloads deployed successfully!"
echo "=========================================="
echo ""
kubectl get pods -n tenant-a
kubectl get pods -n tenant-b
kubectl get svc -n tenant-a
kubectl get svc -n tenant-b
echo ""
echo "Next step: Run ./scripts/06-run-tests.sh or run individual test scripts"

