# AWS Deployment Guide

**Note**: This guide will be expanded once local testing is complete. The following outlines the approach for deploying the testbed to AWS EKS.

## Overview

After successfully testing locally with kind, you can deploy the same testbed to AWS EKS for:
- Production-like environment testing
- Multi-AZ deployment validation
- Cloud-specific security features
- Scalability testing

## Prerequisites

- AWS account with appropriate permissions
- AWS CLI installed and configured
- eksctl or Terraform for cluster creation
- kubectl configured for EKS

## Deployment Steps (Outline)

### Step 1: Create EKS Cluster

**Option A: Using eksctl**
```bash
eksctl create cluster \
  --name cilium-multitenant \
  --region us-west-2 \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed
```

**Option B: Using Terraform**
- Create EKS cluster with Terraform
- Configure VPC, subnets, security groups
- Set up IAM roles and policies

### Step 2: Install Cilium on EKS

```bash
# Cilium on EKS requires replacing VPC CNI
# Follow official Cilium EKS installation guide
cilium install --version 1.14.0
```

**Important**: EKS uses AWS VPC CNI by default. Cilium installation will replace it.

### Step 3: Apply Manifests

The same manifests from `manifests/` directory can be used:
```bash
kubectl apply -f manifests/rbac/
kubectl apply -f manifests/workloads/
kubectl apply -f manifests/cilium-policies/
```

### Step 4: Configure CloudWatch Integration

```bash
# Install CloudWatch agent for metrics
# Configure Prometheus to export to CloudWatch
```

### Step 5: Run Tests

Same test scripts can be used:
```bash
./tests/connectivity.sh
./tests/attacks.sh
./tests/performance.sh
```

## AWS-Specific Considerations

### Network Configuration
- VPC CNI replacement with Cilium
- Security group configuration
- Route table management
- Multi-AZ networking

### Security
- IAM roles for service accounts (IRSA)
- AWS Secrets Manager integration
- CloudTrail logging
- GuardDuty integration

### Monitoring
- CloudWatch metrics
- CloudWatch Logs
- X-Ray tracing (optional)
- Cost monitoring

### Cost Optimization
- Spot instances for worker nodes
- Auto-scaling configuration
- Resource tagging
- Cost allocation tags

## Differences from Local Setup

1. **CNI Replacement**: EKS requires replacing VPC CNI with Cilium
2. **IAM Integration**: Use IRSA for service account permissions
3. **Network Policies**: May need to adjust for VPC routing
4. **Load Balancers**: Use AWS Load Balancer Controller
5. **Storage**: Use EBS CSI driver for persistent volumes

## Testing on AWS

1. **Multi-AZ Testing**: Deploy pods across availability zones
2. **Network Performance**: Test cross-AZ latency
3. **Scalability**: Test with larger node counts
4. **Cloud Integration**: Test AWS service integration

## Cost Estimation

- EKS Control Plane: ~$0.10/hour
- Worker Nodes (3x t3.medium): ~$0.15/hour
- Data Transfer: Variable
- Storage: Minimal for test workloads

**Estimated Monthly Cost**: ~$180-250 for continuous testing

## Next Steps

1. Complete local testing first
2. Document local test results
3. Create AWS-specific deployment scripts
4. Test on AWS with same scenarios
5. Compare local vs AWS results

## References

- [Cilium on EKS](https://docs.cilium.io/en/stable/installation/k8s-install-eks/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [eksctl Documentation](https://eksctl.io/)

---

**Status**: This guide will be expanded with detailed steps after local testing is complete.

