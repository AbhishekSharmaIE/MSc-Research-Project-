#!/bin/bash
# Export Prometheus Metrics for Analysis
# Collects Cilium and performance metrics from Prometheus

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="${PROJECT_ROOT}/results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "=========================================="
echo "Exporting Prometheus Metrics"
echo "=========================================="

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Check if Prometheus is installed
if ! kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus &>/dev/null; then
    echo "Error: Prometheus is not installed."
    echo "Please run: ./scripts/10-install-prometheus.sh"
    exit 1
fi

# Create results directory
mkdir -p "${RESULTS_DIR}/prometheus-metrics"

# Port-forward Prometheus (in background)
echo "Setting up Prometheus connection..."
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
PF_PID=$!
sleep 5

# Function to query Prometheus
query_prometheus() {
    local QUERY=$1
    local OUTPUT_FILE=$2
    curl -s "http://localhost:9090/api/v1/query?query=$(echo "$QUERY" | jq -sRr @uri)" > "$OUTPUT_FILE" 2>/dev/null || echo "{}"
}

# Function to query range
query_range() {
    local QUERY=$1
    local START=$2
    local END=$3
    local STEP=${4:-15s}
    local OUTPUT_FILE=$5
    curl -s "http://localhost:9090/api/v1/query_range?query=$(echo "$QUERY" | jq -sRr @uri)&start=$START&end=$END&step=$STEP" > "$OUTPUT_FILE" 2>/dev/null || echo "{}"
}

echo "Collecting Cilium metrics..."

# Cilium-specific metrics
METRICS_DIR="${RESULTS_DIR}/prometheus-metrics/${TIMESTAMP}"
mkdir -p "${METRICS_DIR}"

# Current time
END_TIME=$(date +%s)
START_TIME=$((END_TIME - 3600))  # Last hour

echo "[1/6] Collecting Cilium drop metrics..."
query_range "rate(cilium_drop_total[5m])" "$START_TIME" "$END_TIME" "15s" "${METRICS_DIR}/cilium-drops.json"

echo "[2/6] Collecting Cilium policy metrics..."
query_range "rate(cilium_policy_count[5m])" "$START_TIME" "$END_TIME" "15s" "${METRICS_DIR}/cilium-policies.json"

echo "[3/6] Collecting Cilium flow metrics..."
query_range "rate(cilium_flows_total[5m])" "$START_TIME" "$END_TIME" "15s" "${METRICS_DIR}/cilium-flows.json"

echo "[4/6] Collecting Cilium CPU usage..."
query_range "rate(process_cpu_seconds_total{job=\"cilium\"}[5m])" "$START_TIME" "$END_TIME" "15s" "${METRICS_DIR}/cilium-cpu.json"

echo "[5/6] Collecting Cilium memory usage..."
query_range "process_resident_memory_bytes{job=\"cilium\"}" "$START_TIME" "$END_TIME" "15s" "${METRICS_DIR}/cilium-memory.json"

echo "[6/6] Collecting network throughput metrics..."
query_range "rate(container_network_receive_bytes_total[5m])" "$START_TIME" "$END_TIME" "15s" "${METRICS_DIR}/network-receive.json"
query_range "rate(container_network_transmit_bytes_total[5m])" "$START_TIME" "$END_TIME" "15s" "${METRICS_DIR}/network-transmit.json"

# Get all Cilium metrics
echo "Exporting all Cilium metrics..."
curl -s "http://localhost:9090/api/v1/label/__name__/values" | jq -r '.data[] | select(. | startswith("cilium_"))' > "${METRICS_DIR}/cilium-metric-names.txt"

# Stop port-forward
kill $PF_PID 2>/dev/null || true

echo ""
echo "=========================================="
echo "Metrics Export Complete!"
echo "=========================================="
echo "Metrics saved to: ${METRICS_DIR}"
echo ""
echo "Files created:"
ls -lh "${METRICS_DIR}"
echo ""
echo "To view metrics in Prometheus UI:"
echo "  kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "  Then open: http://localhost:9090"

