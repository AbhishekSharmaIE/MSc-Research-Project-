#!/bin/bash
# Configure Grafana with Cilium Dashboard
# Adds the official Cilium dashboard to Grafana

set -e

echo "=========================================="
echo "Configuring Grafana with Cilium Dashboard"
echo "=========================================="

# Check if Grafana is installed
if ! kubectl get svc -n monitoring prometheus-grafana &>/dev/null; then
    echo "Error: Grafana is not installed."
    echo "Please run: ./scripts/10-install-prometheus.sh"
    exit 1
fi

# Get Grafana pod name
GRAFANA_POD=$(kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}')

if [ -z "$GRAFANA_POD" ]; then
    echo "Error: Could not find Grafana pod"
    exit 1
fi

echo "Found Grafana pod: $GRAFANA_POD"
echo ""
echo "To add Cilium dashboard manually:"
echo "1. Port-forward Grafana:"
echo "   kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80"
echo ""
echo "2. Open http://localhost:3000"
echo "   Login: admin / admin"
echo ""
echo "3. Go to Dashboards → Import"
echo "   Dashboard ID: 13332"
echo "   Or use URL: https://grafana.com/grafana/dashboards/13332"
echo ""
echo "4. Select Prometheus as datasource"
echo ""
echo "Alternative: Use Grafana API to import dashboard automatically..."
echo ""

# Try to import dashboard via API (requires port-forward)
echo "Attempting automatic import via API..."
echo "Note: You need to port-forward Grafana first:"
echo "  kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80"
echo ""
echo "Then run this script again, or import manually using the steps above."

