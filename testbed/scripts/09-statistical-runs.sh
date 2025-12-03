#!/bin/bash
# Statistical Test Runs
# Runs multiple iterations for statistical significance

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="${PROJECT_ROOT}/results"
NUM_RUNS=${1:-5}  # Default to 5 runs, can be overridden

echo "=========================================="
echo "Statistical Test Runs"
echo "Running ${NUM_RUNS} iterations for each scenario"
echo "=========================================="
echo ""

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

# Create results directory
mkdir -p "${RESULTS_DIR}/statistical-runs"

# Function to run performance test for a scenario
run_performance_test() {
    local SCENARIO=$1
    local RUN_NUM=$2
    local OUTPUT_FILE="${RESULTS_DIR}/statistical-runs/${SCENARIO}-run${RUN_NUM}-$(date +%Y%m%d-%H%M%S).log"
    
    echo "  Run ${RUN_NUM}: Running performance test..."
    "${PROJECT_ROOT}/tests/performance.sh" > "${OUTPUT_FILE}" 2>&1
    echo "  Run ${RUN_NUM}: Completed - saved to ${OUTPUT_FILE}"
}

# Run statistical tests
for i in $(seq 1 ${NUM_RUNS}); do
    echo "=========================================="
    echo "Iteration ${i} of ${NUM_RUNS}"
    echo "=========================================="
    
    # Baseline
    echo "[Iteration ${i}] Baseline scenario..."
    kubectl delete networkpolicy --all --all-namespaces 2>/dev/null || true
    kubectl delete cnp --all --all-namespaces 2>/dev/null || true
    sleep 5
    run_performance_test "baseline" ${i}
    
    # NetworkPolicy
    echo "[Iteration ${i}] NetworkPolicy scenario..."
    kubectl apply -f "${PROJECT_ROOT}/manifests/network-policies/deny-cross-namespace.yaml" 2>/dev/null || true
    sleep 5
    run_performance_test "networkpolicy" ${i}
    kubectl delete networkpolicy -n tenant-a deny-cross-ns 2>/dev/null || true
    
    # CiliumNetworkPolicy
    echo "[Iteration ${i}] CiliumNetworkPolicy L7 scenario..."
    kubectl apply -f "${PROJECT_ROOT}/manifests/cilium-policies/tenant-a-l7-policy.yaml" 2>/dev/null || true
    kubectl apply -f "${PROJECT_ROOT}/manifests/cilium-policies/tenant-b-l7-policy.yaml" 2>/dev/null || true
    sleep 5
    run_performance_test "cilium-l7" ${i}
    kubectl delete cnp -n tenant-a tenant-a-l7-policy 2>/dev/null || true
    kubectl delete cnp -n tenant-b tenant-b-l7-policy 2>/dev/null || true
    
    # Wait between iterations
    if [ $i -lt ${NUM_RUNS} ]; then
        echo "Waiting 30 seconds before next iteration..."
        sleep 30
    fi
done

echo ""
echo "=========================================="
echo "Statistical Test Runs Completed!"
echo "=========================================="
echo "Results saved in: ${RESULTS_DIR}/statistical-runs"
echo ""
echo "Next steps:"
echo "1. Analyze results for statistical significance"
echo "2. Calculate mean, standard deviation, confidence intervals"
echo "3. Generate comparison charts"

