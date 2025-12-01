# Project Summary

## Overview

This testbed implements a comprehensive eBPF/Cilium-based multi-tenant Kubernetes security evaluation environment. It provides automated setup, testing, and benchmarking capabilities for research purposes.

## Project Structure

```
testbed/
├── README.md                    # Main project documentation
├── QUICKSTART.md                # Quick start guide
├── PROJECT_SUMMARY.md           # This file
├── .gitignore                   # Git ignore rules
│
├── scripts/                     # Automation scripts
│   ├── 01-prerequisites.sh     # Install dependencies
│   ├── 02-create-cluster.sh    # Create kind cluster
│   ├── 03-install-cilium.sh    # Install Cilium & Hubble
│   ├── 04-setup-tenants.sh     # Setup multi-tenant env
│   ├── 05-deploy-workloads.sh  # Deploy sample apps
│   └── 06-run-tests.sh         # Run all tests
│
├── manifests/                   # Kubernetes manifests
│   ├── cluster/
│   │   └── kind-multi.yaml     # Kind cluster config (3 nodes)
│   ├── rbac/
│   │   ├── tenant-a-rbac.yaml  # RBAC for tenant-a
│   │   ├── tenant-b-rbac.yaml  # RBAC for tenant-b
│   │   ├── tenant-a-quota.yaml # Resource quotas
│   │   └── tenant-b-quota.yaml
│   ├── workloads/
│   │   ├── tenant-a-deployment.yaml # nginx deployment
│   │   ├── tenant-a-service.yaml
│   │   ├── tenant-b-deployment.yaml
│   │   └── tenant-b-service.yaml
│   ├── network-policies/
│   │   └── deny-cross-namespace.yaml # Traditional NetworkPolicy
│   ├── cilium-policies/
│   │   ├── tenant-a-l7-policy.yaml  # Cilium L7 policy
│   │   ├── tenant-b-l7-policy.yaml
│   │   └── strict-isolation.yaml    # Strict isolation
│   └── monitoring/
│       └── metrics-server.yaml      # Optional metrics server
│
├── tests/                        # Test scripts
│   ├── connectivity.sh          # Connectivity tests
│   ├── attacks.sh              # Attack simulations
│   └── performance.sh          # Performance benchmarks
│
├── docs/                        # Documentation
│   ├── SETUP.md                # Detailed setup guide
│   └── TESTING.md              # Testing procedures
│
└── results/                     # Test results (gitignored)
    └── (generated during tests)
```

## Key Features

### 1. Automated Setup
- One-command installation of all prerequisites
- Automated cluster creation with kind
- Automated Cilium and Hubble installation
- Automated multi-tenant environment setup

### 2. Multi-Tenant Isolation
- Two tenant namespaces (tenant-a, tenant-b)
- RBAC policies per tenant
- Resource quotas and limits
- Network isolation policies

### 3. Security Testing
- Baseline connectivity tests
- Traditional NetworkPolicy enforcement
- eBPF/Cilium L7 policy enforcement
- Attack simulation scenarios
- Cross-tenant access attempts

### 4. Performance Benchmarking
- Network throughput (iperf3)
- HTTP latency (hey/wrk)
- Resource utilization (CPU/memory)
- Concurrent connection testing

### 5. Observability
- Hubble UI for flow visualization
- Hubble CLI for flow analysis
- Cilium monitor for policy decisions
- Prometheus metrics (optional)

## Test Scenarios

### Scenario 1: Baseline (No Policies)
- Objective: Establish baseline connectivity
- Tests: Pod-to-pod, pod-to-service, cross-namespace
- Metrics: Latency, throughput, resource usage

### Scenario 2: NetworkPolicy
- Objective: Test traditional Kubernetes NetworkPolicy
- Tests: Cross-namespace blocking, same-namespace allowing
- Metrics: Policy enforcement overhead

### Scenario 3: CiliumNetworkPolicy L7
- Objective: Test eBPF-based L7 enforcement
- Tests: HTTP method filtering, path-based access control
- Metrics: L7 processing overhead

### Scenario 4: Attack Simulation
- Objective: Validate security policies
- Tests: Unauthorized access, privilege escalation, port scanning
- Metrics: Detection rate, prevention rate

### Scenario 5: Performance Comparison
- Objective: Compare eBPF vs traditional approaches
- Tests: Throughput, latency, CPU, memory
- Metrics: Overhead analysis

## Technology Stack

- **Kubernetes**: v1.28+ (via kind)
- **CNI**: Cilium (eBPF-based)
- **Observability**: Hubble (UI + CLI)
- **Container Runtime**: Docker (via kind)
- **Testing Tools**: iperf3, hey/wrk, curl
- **Monitoring**: Prometheus (optional), metrics-server

## Usage Workflow

1. **Setup** (one-time):
   ```bash
   ./scripts/01-prerequisites.sh
   ./scripts/02-create-cluster.sh
   ./scripts/03-install-cilium.sh
   ./scripts/04-setup-tenants.sh
   ./scripts/05-deploy-workloads.sh
   ```

2. **Testing**:
   ```bash
   # Individual tests
   ./tests/connectivity.sh
   ./tests/attacks.sh
   ./tests/performance.sh
   
   # Or run all
   ./scripts/06-run-tests.sh
   ```

3. **Policy Testing**:
   ```bash
   # Apply NetworkPolicy
   kubectl apply -f manifests/network-policies/deny-cross-namespace.yaml
   
   # Apply CiliumNetworkPolicy
   kubectl apply -f manifests/cilium-policies/tenant-a-l7-policy.yaml
   ```

4. **Observability**:
   ```bash
   # Hubble UI
   kubectl -n kube-system port-forward svc/hubble-ui 12000:80
   
   # Hubble CLI
   hubble observe --last 50
   
   # Cilium monitor
   cilium monitor
   ```

## Expected Deliverables

1. **Test Results**: Connectivity matrices, performance metrics, attack simulation results
2. **Flow Logs**: Hubble flow data for each test scenario
3. **Metrics**: CPU, memory, network throughput, latency measurements
4. **Documentation**: Test procedures, findings, analysis

## Research Contributions

1. **Systematic Evaluation**: Comprehensive assessment of eBPF effectiveness
2. **Performance Benchmarking**: Quantitative comparison with traditional approaches
3. **Implementation Guidelines**: Practical deployment recommendations
4. **Best Practices**: Integration strategies for production environments

## Next Steps (AWS Deployment)

For AWS deployment, consider:
- EKS cluster creation
- Cilium installation on EKS
- Multi-AZ deployment
- CloudWatch integration
- IAM role configuration
- VPC CNI replacement

See `docs/AWS_DEPLOYMENT.md` (to be created) for AWS-specific instructions.

## References

- [Cilium Documentation](https://docs.cilium.io/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Multi-tenancy](https://kubernetes.io/docs/concepts/security/multi-tenancy/)
- [eBPF Documentation](https://ebpf.io/)

## Support

For issues or questions:
1. Check [SETUP.md](docs/SETUP.md) troubleshooting section
2. Review test logs in `results/` directory
3. Check Cilium status: `cilium status`
4. Review Hubble flows: `hubble observe --last 50`

