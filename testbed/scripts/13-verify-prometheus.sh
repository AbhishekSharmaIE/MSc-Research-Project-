#!/bin/bash
# Verify Prometheus Installation and Cilium Metrics Scraping

set -e

echo "=========================================="
echo "Verifying Prometheus Installation"
echo "=========================================="

# Check Prometheus pods
echo "[1/4] Checking Prometheus pods..."
if kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus | grep -q Running; then
    echo "✓ Prometheus pods are running"
    kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
else
    echo "✗ Prometheus pods are not running"
    exit 1
fi

# Check Grafana pods
echo ""
echo "[2/4] Checking Grafana pods..."
if kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana | grep -q Running; then
    echo "✓ Grafana pods are running"
    kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
else
    echo "✗ Grafana pods are not running"
    exit 1
fi

# Check services
echo ""
echo "[3/4] Checking services..."
kubectl get svc -n monitoring | grep -E "(prometheus|grafana)" || echo "Services not found"

# Check if Cilium metrics are being scraped
echo ""
echo "[4/4] Checking Cilium metrics availability..."
echo "Starting port-forward to check Prometheus targets..."
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
PF_PID=$!
sleep 5

# Check targets
TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null | jq -r '.data.activeTargets[] | select(.labels.job=="cilium") | .health' 2>/dev/null || echo "")

kill $PF_PID 2>/dev/null || true

if [ -n "$TARGETS" ]; then
    echo "✓ Cilium metrics target found in Prometheus"
else
    echo "⚠ Warning: Cilium metrics target not found yet"
    echo "  This is normal if Cilium was just installed"
    echo "  Metrics will appear after a few minutes"
fi

echo ""
echo "=========================================="
echo "Verification Complete!"
echo "=========================================="
echo ""
echo "To access Prometheus:"
echo "  kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "  Then open: http://localhost:9090"
echo ""
echo "To access Grafana:"
echo "  kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80"
echo "  Then open: http://localhost:3000"
echo ""
echo "To check Prometheus targets:"
echo "  Open http://localhost:9090/targets after port-forwarding"

