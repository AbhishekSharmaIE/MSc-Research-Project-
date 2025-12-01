#!/bin/bash
# Run All Test Scenarios
# Executes connectivity, attack, and performance tests

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="${PROJECT_ROOT}/results"

echo "=========================================="
echo "Running All Test Scenarios"
echo "=========================================="

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Run tests
echo "[1/3] Running connectivity tests..."
"${PROJECT_ROOT}/tests/connectivity.sh" | tee "${RESULTS_DIR}/connectivity-$(date +%Y%m%d-%H%M%S).log"

echo "[2/3] Running attack simulation tests..."
"${PROJECT_ROOT}/tests/attacks.sh" | tee "${RESULTS_DIR}/attacks-$(date +%Y%m%d-%H%M%S).log"

echo "[3/3] Running performance benchmarks..."
"${PROJECT_ROOT}/tests/performance.sh" | tee "${RESULTS_DIR}/performance-$(date +%Y%m%d-%H%M%S).log"

# Collect Hubble flows
echo "Collecting Hubble flow data..."
hubble observe --last 1000 --output json > "${RESULTS_DIR}/hubble-flows-$(date +%Y%m%d-%H%M%S).json" 2>/dev/null || echo "Hubble CLI not available, skipping flow export"

echo ""
echo "=========================================="
echo "All tests completed!"
echo "=========================================="
echo "Results saved to: ${RESULTS_DIR}"
echo ""
ls -lh "${RESULTS_DIR}"

