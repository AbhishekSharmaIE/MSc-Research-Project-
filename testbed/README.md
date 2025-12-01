# eBPF/Cilium Multi-Tenant Kubernetes Testbed

This project implements a comprehensive testbed for evaluating eBPF-based security mechanisms (via Cilium) in multi-tenant Kubernetes environments.

## Project Structure

```
testbed/
├── README.md                 # This file
├── scripts/                  # Setup and automation scripts
│   ├── 01-prerequisites.sh  # Install dependencies
│   ├── 02-create-cluster.sh # Create kind cluster
│   ├── 03-install-cilium.sh # Install Cilium and Hubble
│   ├── 04-setup-tenants.sh  # Create namespaces, RBAC, quotas
│   ├── 05-deploy-workloads.sh # Deploy sample applications
│   └── 06-run-tests.sh      # Execute all test scenarios
├── manifests/               # Kubernetes manifests
│   ├── cluster/             # Cluster configuration
│   ├── rbac/                # RBAC definitions
│   ├── network-policies/    # NetworkPolicy manifests
│   ├── cilium-policies/     # CiliumNetworkPolicy manifests
│   ├── workloads/           # Application deployments
│   └── monitoring/          # Prometheus/Grafana setup
├── tests/                   # Test scripts
│   ├── connectivity.sh     # Basic connectivity tests
│   ├── attacks.sh          # Attack simulation scenarios
│   └── performance.sh      # Performance benchmarking
├── docs/                    # Documentation
│   ├── SETUP.md            # Detailed setup guide
│   └── TESTING.md          # Testing procedures
└── results/                 # Collected test results (gitignored)

```

## Quick Start

### Prerequisites

- Ubuntu 22.04 LTS (or compatible Linux distribution)
- sudo access
- Internet connection

### Automated Setup

Run the setup scripts in order:

```bash
cd testbed
chmod +x scripts/*.sh

# Step 1: Install prerequisites
./scripts/01-prerequisites.sh

# Step 2: Create kind cluster
./scripts/02-create-cluster.sh

# Step 3: Install Cilium and Hubble
./scripts/03-install-cilium.sh

# Step 4: Setup multi-tenant environment
./scripts/04-setup-tenants.sh

# Step 5: Deploy workloads
./scripts/05-deploy-workloads.sh

# Step 6: Run tests
./scripts/06-run-tests.sh
```

### Manual Setup

See [docs/SETUP.md](docs/SETUP.md) for detailed manual setup instructions.

## Test Scenarios

1. **Baseline Connectivity** - Verify default pod-to-pod communication
2. **NetworkPolicy Enforcement** - Test traditional Kubernetes NetworkPolicy
3. **CiliumNetworkPolicy L7** - Test eBPF-based L7 enforcement
4. **Cross-Tenant Attacks** - Simulate unauthorized access attempts
5. **Performance Benchmarking** - Compare eBPF vs traditional approaches

## Observability

- **Hubble UI**: `kubectl -n kube-system port-forward svc/hubble-ui 12000:80`
- **Hubble CLI**: `hubble observe --last 50`
- **Cilium Monitor**: `cilium monitor`

## Performance Metrics

- Network throughput (iperf3)
- Latency measurements (hey/wrk)
- CPU/Memory utilization (Prometheus)
- Flow logs (Hubble)

## Documentation

- [Setup Guide](docs/SETUP.md) - Detailed installation instructions
- [Testing Guide](docs/TESTING.md) - Test procedures and scenarios

## References

- [Cilium Documentation](https://docs.cilium.io/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Multi-tenancy](https://kubernetes.io/docs/concepts/security/multi-tenancy/)

## License

This project is for research purposes as part of MSc in Cloud Computing.

