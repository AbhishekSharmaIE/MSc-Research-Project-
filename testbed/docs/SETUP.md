# Detailed Setup Guide

This guide provides step-by-step instructions for setting up the eBPF/Cilium multi-tenant Kubernetes testbed.

## Prerequisites

### System Requirements
- **OS**: Ubuntu 22.04 LTS (or compatible Linux distribution)
- **CPU**: 4+ cores recommended (8+ for better performance)
- **RAM**: 8GB minimum (16GB+ recommended)
- **Storage**: 20GB+ free disk space
- **Network**: Internet connection for downloading images and packages

### Software Requirements
- Docker (for kind)
- kubectl (Kubernetes CLI)
- kind (Kubernetes in Docker)
- helm (package manager)
- Cilium CLI

## Installation Steps

### Step 1: Install Prerequisites

Run the automated prerequisites script:

```bash
cd testbed
chmod +x scripts/*.sh
./scripts/01-prerequisites.sh
```

**Manual Installation** (if script fails):

1. **Update system:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install Docker:**
   ```bash
   sudo apt install -y docker.io
   sudo systemctl enable --now docker
   sudo usermod -aG docker $USER
   # Log out and back in for group changes
   ```

3. **Install kubectl:**
   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   ```

4. **Install kind:**
   ```bash
   curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64"
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/
   ```

5. **Install helm:**
   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

6. **Install Cilium CLI:**
   ```bash
   CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
   CLI_ARCH=amd64
   if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
   curl -L --remote-name-all "https://github.com/cilium/cilium-cli/releases/${CILIUM_CLI_VERSION}/download/cilium-linux-${CLI_ARCH}.tar.gz"
   tar xzvfC "cilium-linux-${CLI_ARCH}.tar.gz" /usr/local/bin
   ```

### Step 2: Create Kind Cluster

```bash
./scripts/02-create-cluster.sh
```

This creates a 3-node cluster:
- 1 control-plane node
- 2 worker nodes

**Verify cluster:**
```bash
kubectl get nodes -o wide
kubectl cluster-info
```

### Step 3: Install Cilium and Hubble

```bash
./scripts/03-install-cilium.sh
```

This will:
- Install Cilium as the CNI plugin
- Replace kube-proxy with eBPF
- Enable Hubble observability with UI

**Verify installation:**
```bash
cilium status --wait
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl -n kube-system get pods -l k8s-app=hubble
```

**Access Hubble UI:**
```bash
kubectl -n kube-system port-forward svc/hubble-ui 12000:80
# Open http://localhost:12000 in browser
```

### Step 4: Setup Multi-Tenant Environment

```bash
./scripts/04-setup-tenants.sh
```

This creates:
- Namespaces: `tenant-a`, `tenant-b`, `platform-tools`
- RBAC roles and bindings for each tenant
- Resource quotas and limit ranges

**Verify:**
```bash
kubectl get namespaces
kubectl get roles,rolebindings -n tenant-a
kubectl get resourcequota -n tenant-a
```

### Step 5: Deploy Workloads

```bash
./scripts/05-deploy-workloads.sh
```

This deploys:
- nginx deployments in each tenant namespace
- ClusterIP services for each deployment

**Verify:**
```bash
kubectl get pods -n tenant-a
kubectl get pods -n tenant-b
kubectl get svc -n tenant-a
```

## Optional: Install Monitoring Stack

For detailed metrics collection:

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Access Grafana
kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80
# Default credentials: admin/prom-operator
```

## Troubleshooting

### Cluster Creation Issues

**Problem**: kind cluster creation fails
**Solution**: 
- Check Docker is running: `sudo systemctl status docker`
- Ensure you're in docker group: `groups | grep docker`
- Check available resources: `free -h` and `df -h`

### Cilium Installation Issues

**Problem**: Cilium pods not ready
**Solution**:
```bash
# Check pod logs
kubectl -n kube-system logs -l k8s-app=cilium

# Check Cilium status
cilium status

# Restart Cilium
cilium uninstall
cilium install
```

### Network Connectivity Issues

**Problem**: Pods cannot communicate
**Solution**:
```bash
# Check Cilium endpoints
cilium endpoint list

# Check network policies
kubectl get networkpolicies --all-namespaces
kubectl get cnp --all-namespaces

# Check Hubble flows
hubble observe --last 50
```

### Resource Constraints

**Problem**: Out of memory or CPU
**Solution**:
- Reduce cluster size in `manifests/cluster/kind-multi.yaml`
- Adjust resource quotas in `manifests/rbac/*-quota.yaml`
- Close other resource-intensive applications

## Next Steps

After setup is complete:

1. **Run connectivity tests**: `./tests/connectivity.sh`
2. **Apply network policies**: See [TESTING.md](TESTING.md)
3. **Run attack simulations**: `./tests/attacks.sh`
4. **Run performance tests**: `./tests/performance.sh`

## References

- [Cilium Quick Install](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)
- [Kind Documentation](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kubernetes Multi-tenancy](https://kubernetes.io/docs/concepts/security/multi-tenancy/)

