#!/bin/bash
# Prerequisites Installation Script
# Installs kubectl, kind, helm, cilium CLI, and Docker

set -e

echo "=========================================="
echo "Installing Prerequisites for eBPF/Cilium Testbed"
echo "=========================================="

# Update system
echo "[1/6] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "[2/6] Installing Docker..."
sudo apt install -y curl apt-transport-https ca-certificates gnupg lsb-release docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
echo "Docker installed. You may need to log out and back in for group changes to take effect."

# Install kubectl
echo "[3/6] Installing kubectl..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# Install kind
echo "[4/6] Installing kind..."
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64"
chmod +x ./kind
sudo mv ./kind /usr/local/bin/
kind --version

# Install helm
echo "[5/6] Installing helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# Install Cilium CLI
echo "[6/6] Installing Cilium CLI..."
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --remote-name-all "https://github.com/cilium/cilium-cli/releases/${CILIUM_CLI_VERSION}/download/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}"
sha256sum --check "cilium-linux-${CLI_ARCH}.tar.gz.sha256sum"
tar xzvfC "cilium-linux-${CLI_ARCH}.tar.gz" /usr/local/bin
rm "cilium-linux-${CLI_ARCH}.tar.gz" "cilium-linux-${CLI_ARCH}.tar.gz.sha256sum"
cilium version --client

echo "=========================================="
echo "Prerequisites installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Log out and back in (or run: newgrp docker) to apply Docker group changes"
echo "2. Run: ./scripts/02-create-cluster.sh"

