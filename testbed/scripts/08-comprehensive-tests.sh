#!/bin/bash
# Comprehensive Test Runner
# Runs all test scenarios systematically and collects data

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="${PROJECT_ROOT}/results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "=========================================="
echo "Comprehensive Test Suite"
echo "=========================================="
echo "Results will be saved to: ${RESULTS_DIR}"
echo ""

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Ensure prerequisites are met
echo "Checking prerequisites..."
if ! kubectl get deployment -n kube-system metrics-server &>/dev/null || ! kubectl top nodes &>/dev/null; then
    echo "Installing metrics-server..."
    "${PROJECT_ROOT}/scripts/install-metrics-server-kind.sh"
fi

# Check Cilium CLI
if ! command -v cilium &> /dev/null; then
    if [ -f "${HOME}/.local/bin/cilium" ]; then
        export PATH="${HOME}/.local/bin:${PATH}"
    fi
fi

# Check if Prometheus should be installed
if [ "${INSTALL_PROMETHEUS:-true}" = "true" ]; then
    if ! kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus &>/dev/null; then
        echo "Installing Prometheus for metrics visualization..."
        "${PROJECT_ROOT}/scripts/10-install-prometheus.sh" || echo "Warning: Prometheus installation failed, continuing without it"
    else
        echo "Prometheus is already installed"
    fi
fi

# Function to run tests for a scenario
run_scenario_tests() {
    local SCENARIO_NAME=$1
    local SCENARIO_DIR="${RESULTS_DIR}/${SCENARIO_NAME}-${TIMESTAMP}"
    mkdir -p "${SCENARIO_DIR}"
    
    echo "=========================================="
    echo "Running Scenario: ${SCENARIO_NAME}"
    echo "=========================================="
    
    # Run connectivity tests
    echo "[1/4] Running connectivity tests..."
    "${PROJECT_ROOT}/tests/connectivity.sh" 2>&1 | tee "${SCENARIO_DIR}/connectivity.log"
    
    # Run attack simulation tests
    echo "[2/4] Running attack simulation tests..."
    "${PROJECT_ROOT}/tests/attacks.sh" 2>&1 | tee "${SCENARIO_DIR}/attacks.log"
    
    # Run performance tests
    echo "[3/4] Running performance benchmarks..."
    "${PROJECT_ROOT}/tests/performance.sh" 2>&1 | tee "${SCENARIO_DIR}/performance.log"
    
    # Collect Hubble flows
    echo "[4/4] Collecting Hubble flow data..."
    if command -v hubble &> /dev/null; then
        hubble observe --last 1000 --output json > "${SCENARIO_DIR}/hubble-flows.json" 2>/dev/null || \
            echo "Warning: Could not collect Hubble flows"
    else
        echo "Warning: Hubble CLI not available, skipping flow collection"
    fi
    
    # Collect resource metrics
    echo "Collecting resource metrics..."
    kubectl top pods --all-namespaces > "${SCENARIO_DIR}/resources.txt" 2>/dev/null || \
        echo "Warning: Could not collect resource metrics (metrics-server may not be ready)"
    
    # Collect Cilium status
    if command -v cilium &> /dev/null; then
        cilium status > "${SCENARIO_DIR}/cilium-status.txt" 2>/dev/null || true
    fi
    
    # Export Prometheus metrics if available
    if kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus &>/dev/null; then
        echo "Exporting Prometheus metrics..."
        "${PROJECT_ROOT}/scripts/11-export-prometheus-metrics.sh" 2>/dev/null || echo "Warning: Could not export Prometheus metrics"
    fi
    
    echo "✓ Scenario ${SCENARIO_NAME} completed"
    echo ""
}

# SCENARIO A: Baseline (No Policies)
echo "=========================================="
echo "SCENARIO A: Baseline (No Policies)"
echo "=========================================="
echo "Removing all policies..."
kubectl delete networkpolicy --all --all-namespaces 2>/dev/null || true
kubectl delete cnp --all --all-namespaces 2>/dev/null || true
sleep 5

run_scenario_tests "baseline"

# SCENARIO B: Traditional NetworkPolicy
echo "=========================================="
echo "SCENARIO B: Traditional NetworkPolicy"
echo "=========================================="
echo "Applying NetworkPolicy..."
kubectl apply -f "${PROJECT_ROOT}/manifests/network-policies/deny-cross-namespace.yaml"
sleep 10  # Wait for policy to be active

run_scenario_tests "networkpolicy"

# SCENARIO C: CiliumNetworkPolicy L7
echo "=========================================="
echo "SCENARIO C: CiliumNetworkPolicy L7"
echo "=========================================="
echo "Removing NetworkPolicy and applying CiliumNetworkPolicy..."
kubectl delete networkpolicy -n tenant-a deny-cross-ns 2>/dev/null || true
kubectl apply -f "${PROJECT_ROOT}/manifests/cilium-policies/tenant-a-l7-policy.yaml"
kubectl apply -f "${PROJECT_ROOT}/manifests/cilium-policies/tenant-b-l7-policy.yaml"
sleep 10  # Wait for policies to be active

run_scenario_tests "cilium-l7"

# Summary
echo "=========================================="
echo "All Test Scenarios Completed!"
echo "=========================================="
echo ""
echo "Results saved in: ${RESULTS_DIR}"
echo ""
echo "Directory structure:"
ls -lh "${RESULTS_DIR}" | grep "${TIMESTAMP}" || ls -lh "${RESULTS_DIR}"
echo ""
echo "Next steps:"
echo "1. Review results in: ${RESULTS_DIR}"
echo "2. Calculate metrics: python3 scripts/calculate-metrics.py"
echo "3. Generate comparison tables and charts"

