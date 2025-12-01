# Quick Start Guide

Get your eBPF/Cilium multi-tenant Kubernetes testbed running in minutes!

## Prerequisites Check

Before starting, ensure you have:
- Ubuntu 22.04+ (or compatible Linux)
- sudo access
- 8GB+ RAM available
- Internet connection

## One-Command Setup (Automated)

```bash
cd testbed
chmod +x scripts/*.sh

# Run all setup steps sequentially
./scripts/01-prerequisites.sh && \
./scripts/02-create-cluster.sh && \
./scripts/03-install-cilium.sh && \
./scripts/04-setup-tenants.sh && \
./scripts/05-deploy-workloads.sh
```

**Note**: After step 1, you may need to log out and back in (or run `newgrp docker`) for Docker group changes.

## Verify Installation

```bash
# Check cluster
kubectl get nodes

# Check Cilium
cilium status

# Check workloads
kubectl get pods -n tenant-a
kubectl get pods -n tenant-b
```

## Quick Tests

### Test 1: Basic Connectivity
```bash
./tests/connectivity.sh
```

### Test 2: Apply Network Policy
```bash
kubectl apply -f manifests/network-policies/deny-cross-namespace.yaml
./tests/connectivity.sh  # Should show blocked cross-namespace traffic
```

### Test 3: Apply Cilium L7 Policy
```bash
kubectl delete networkpolicy -n tenant-a deny-cross-ns
kubectl apply -f manifests/cilium-policies/tenant-a-l7-policy.yaml
./tests/attacks.sh  # Test L7 enforcement
```

## Access Observability Tools

### Hubble UI
```bash
kubectl -n kube-system port-forward svc/hubble-ui 12000:80
# Open http://localhost:12000
```

### Hubble CLI
```bash
hubble observe --last 50
hubble observe --from-pod web-a --type l7
```

### Cilium Monitor
```bash
cilium monitor --json | jq .
```

## Common Commands

```bash
# View all pods
kubectl get pods --all-namespaces

# View services
kubectl get svc --all-namespaces

# View network policies
kubectl get networkpolicies --all-namespaces
kubectl get cnp --all-namespaces

# View Cilium status
cilium status

# View Hubble flows
hubble observe --last 20

# Test connectivity manually
kubectl run -n tenant-b test --image=radial/busyboxplus:curl --rm -i --restart=Never -- \
  curl -sS http://web-a.tenant-a.svc.cluster.local/status
```

## Cleanup

To tear down the testbed:

```bash
kind delete cluster --name cilium-multitenant
```

## Next Steps

1. Read [SETUP.md](docs/SETUP.md) for detailed setup instructions
2. Read [TESTING.md](docs/TESTING.md) for comprehensive test scenarios
3. Run full test suite: `./scripts/06-run-tests.sh`
4. Collect results from `results/` directory

## Troubleshooting

**Issue**: Docker permission denied
**Fix**: `sudo usermod -aG docker $USER` then log out/in

**Issue**: Cluster creation fails
**Fix**: Check Docker is running: `sudo systemctl status docker`

**Issue**: Cilium pods not ready
**Fix**: Check logs: `kubectl -n kube-system logs -l k8s-app=cilium`

**Issue**: Tests fail
**Fix**: Ensure all setup steps completed successfully

## Getting Help

- Check [SETUP.md](docs/SETUP.md) for detailed troubleshooting
- Review Cilium logs: `kubectl -n kube-system logs -l k8s-app=cilium`
- Check Cilium status: `cilium status`
- View Hubble flows: `hubble observe --last 50`

