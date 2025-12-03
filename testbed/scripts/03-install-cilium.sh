#!/bin/bash
# Install Cilium and Hubble
# Installs Cilium as CNI and enables Hubble observability

set -e

CLUSTER_NAME="cilium-multitenant"

echo "=========================================="
echo "Installing Cilium and Hubble"
echo "=========================================="

# Check if Cilium CLI is installed, install if missing
if ! command -v cilium &> /dev/null; then
    echo "[0/3] Cilium CLI not found. Installing..."
    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
    CLI_ARCH=amd64
    if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
    
    TAR_FILE="cilium-linux-${CLI_ARCH}.tar.gz"
    CHECKSUM_FILE="${TAR_FILE}.sha256sum"
    BASE_URL="https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}"
    
    echo "Downloading Cilium CLI ${CILIUM_CLI_VERSION} for ${CLI_ARCH}..."
    curl -L -o "${TAR_FILE}" "${BASE_URL}/${TAR_FILE}"
    curl -L -o "${CHECKSUM_FILE}" "${BASE_URL}/${CHECKSUM_FILE}" 2>/dev/null || echo "Warning: Could not download checksum file"
    
    # Verify checksum if available
    if [ -f "${CHECKSUM_FILE}" ] && [ -s "${CHECKSUM_FILE}" ]; then
        echo "Verifying checksum..."
        sha256sum --check "${CHECKSUM_FILE}" || echo "Warning: Checksum verification failed, continuing anyway..."
    fi
    
    echo "Installing Cilium CLI to /usr/local/bin..."
    echo "1234" | sudo -S tar xzvfC "${TAR_FILE}" /usr/local/bin
    rm -f "${TAR_FILE}" "${CHECKSUM_FILE}"
    
    # Verify installation
    if command -v cilium &> /dev/null; then
        echo "Cilium CLI installed successfully."
        cilium version --client
    else
        echo "Error: Cilium CLI installation failed."
        exit 1
    fi
fi

# Check if cluster exists (using kubectl instead of kind to avoid docker permission issues)
if ! kubectl get nodes -o name 2>/dev/null | grep -q "node"; then
    echo "Error: Cluster '${CLUSTER_NAME}' not found or not accessible."
    echo "Please run ./scripts/02-create-cluster.sh first"
    exit 1
fi

# Set kubectl context
kubectl config use-context "kind-${CLUSTER_NAME}"

# Check if Cilium is already installed
if kubectl get daemonset -n kube-system cilium &>/dev/null; then
    echo "[1/3] Cilium is already installed. Skipping installation..."
    echo "[2/3] Checking Cilium status..."
    cilium status --wait || true
else
    # Install Cilium
    echo "[1/3] Installing Cilium..."
    cilium install --wait
    
    # Wait for Cilium to be ready
    echo "[2/3] Waiting for Cilium to be ready..."
    cilium status --wait
fi

# Check if Hubble is already enabled
if kubectl get deployment -n kube-system hubble-relay &>/dev/null; then
    echo "[3/3] Hubble is already enabled. Skipping..."
else
    # Enable Hubble with UI
    echo "[3/3] Enabling Hubble observability..."
    cilium hubble enable --ui
fi

# Wait for Hubble pods
echo "Waiting for Hubble pods to be ready..."
kubectl -n kube-system wait --for=condition=ready pod -l k8s-app=hubble-relay --timeout=300s || true
kubectl -n kube-system wait --for=condition=ready pod -l k8s-app=hubble-ui --timeout=300s || true

# Display status
echo ""
echo "=========================================="
echo "Cilium and Hubble installation complete!"
echo "=========================================="
echo ""
cilium status
echo ""
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl -n kube-system get pods -l k8s-app=hubble
echo ""
echo "To access Hubble UI, run:"
echo "  kubectl -n kube-system port-forward svc/hubble-ui 12000:80"
echo "  Then open http://localhost:12000 in your browser"
echo ""
echo "Next step: Run ./scripts/04-setup-tenants.sh"

