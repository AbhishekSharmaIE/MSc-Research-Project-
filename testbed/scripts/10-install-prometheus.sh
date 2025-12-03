#!/bin/bash
# Install Prometheus and Grafana for Metrics Visualization
# Uses Helm to install kube-prometheus-stack

set -e

CLUSTER_NAME="cilium-multitenant"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "Installing Prometheus and Grafana"
echo "=========================================="

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: Helm is not installed. Please install helm first."
    echo "Run: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    exit 1
fi

# Check if Prometheus is already installed
if helm list -n monitoring | grep -q prometheus; then
    echo "Prometheus is already installed. Skipping installation."
    echo "To reinstall, run: helm uninstall prometheus -n monitoring"
    exit 0
fi

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Add Prometheus Helm repository
echo "[1/4] Adding Prometheus Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create values file for Cilium integration
echo "[2/4] Creating Prometheus configuration for Cilium..."
cat > /tmp/prometheus-values.yaml <<EOF
# Prometheus configuration optimized for Cilium metrics
prometheus:
  prometheusSpec:
    # Scrape Cilium metrics
    additionalScrapeConfigs:
      - job_name: 'cilium'
        kubernetes_sd_configs:
          - role: pod
            namespaces:
              names:
                - kube-system
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_label_k8s_app]
            action: keep
            regex: cilium
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: pod
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: namespace
        metric_relabel_configs:
          - source_labels: [__name__]
            regex: 'cilium_.*'
            action: keep
    
    # Retention period (30 days for research)
    retention: 30d
    
    # Storage size
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 20Gi
    
    # Resource limits
    resources:
      requests:
        cpu: 500m
        memory: 2Gi
      limits:
        cpu: 2000m
        memory: 4Gi

# Grafana configuration
grafana:
  enabled: true
  adminPassword: admin
  service:
    type: NodePort
    nodePort: 30000
  # Cilium dashboard will be added manually after installation

# Node exporter for node metrics
nodeExporter:
  enabled: true

# Kube-state-metrics for Kubernetes metrics
kubeStateMetrics:
  enabled: true

# Alertmanager (optional, disabled for simplicity)
alertmanager:
  enabled: false
EOF

# Install Prometheus stack
echo "[3/4] Installing Prometheus stack (this may take 3-5 minutes)..."
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --values /tmp/prometheus-values.yaml \
    --wait --timeout=10m

# Wait for pods to be ready
echo "[4/4] Waiting for Prometheus pods to be ready..."
kubectl wait --for=condition=ready pod -n monitoring -l app.kubernetes.io/name=prometheus --timeout=300s || true
kubectl wait --for=condition=ready pod -n monitoring -l app.kubernetes.io/name=grafana --timeout=300s || true

# Cleanup temp file
rm -f /tmp/prometheus-values.yaml

echo ""
echo "=========================================="
echo "Prometheus and Grafana Installation Complete!"
echo "=========================================="
echo ""
echo "Access Prometheus UI:"
echo "  kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "  Then open: http://localhost:9090"
echo ""
echo "Access Grafana UI:"
echo "  kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80"
echo "  Then open: http://localhost:3000"
echo ""
echo "Get Grafana admin password:"
echo "  kubectl get secret -n monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d && echo"
echo ""
echo "Or use default: admin"
echo ""
echo "Useful Prometheus queries for Cilium:"
echo "  - Cilium drops: rate(cilium_drop_total[5m])"
echo "  - Cilium policy: rate(cilium_policy_count[5m])"
echo "  - Cilium flows: rate(cilium_flows_total[5m])"
echo "  - Cilium CPU: rate(process_cpu_seconds_total{job=\"cilium\"}[5m])"
echo ""
echo "Check status:"
echo "  kubectl get pods -n monitoring"
echo "  kubectl get svc -n monitoring"

