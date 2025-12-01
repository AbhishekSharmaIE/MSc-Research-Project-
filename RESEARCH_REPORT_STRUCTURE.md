# Securing Multi-Tenant Kubernetes Clusters Using eBPF Technology
## Research Report Structure

---

## Contents

1. Introduction
   1.1 Problem
   1.2 Motivation
   1.3 Approach
   1.4 Challenges
      1.4.1 Multi-Tenant Isolation Complexity
      1.4.2 Performance Overhead Considerations
      1.4.3 Policy Management and Scalability
   1.5 Structure of the Dissertation

2. Related Works
   2.1 Container Security Evolution
      2.1.1 Container Security Challenges
      2.1.2 CI/CD Pipeline Security
      2.1.3 Multi-Tenant Security Approaches
   2.2 Kubernetes Security Mechanisms
      2.2.1 Traditional Network Policies
      2.2.2 RBAC and Namespace Isolation
      2.2.3 Service Mesh Security Solutions
   2.3 eBPF Technology and Applications
      2.3.1 eBPF Fundamentals and Architecture
      2.3.2 eBPF in Cloud-Native Environments
      2.3.3 Cilium: eBPF-Powered CNI
   2.4 Summary and Research Gaps
      2.4.1 Summary of Progress
      2.4.2 Open Implementation Challenges

3. Hypotheses and Evaluation Framework
   3.1 Research Question
   3.2 Proposed Hypotheses
   3.3 Approach for Validating the Hypothesis
   3.4 Evaluation Metrics
      3.4.1 Security Effectiveness Metrics
      3.4.2 Performance Metrics
      3.4.3 Observability Metrics

4. Architecture and Implementation
   4.1 Testbed Design
      4.1.1 Cluster Architecture
      4.1.2 Multi-Tenant Environment Configuration
      4.1.3 Network Topology
   4.2 Cilium eBPF Implementation
      4.2.1 Cilium Installation and Configuration
      4.2.2 eBPF Program Deployment
      4.2.3 Hubble Observability Setup
   4.3 Security Policy Implementation
      4.3.1 Traditional NetworkPolicy Configuration
      4.3.2 CiliumNetworkPolicy L7 Enforcement
      4.3.3 RBAC and Resource Quotas
   4.4 Testing Framework
      4.4.1 Connectivity Testing
      4.4.2 Attack Simulation Framework
      4.4.3 Performance Benchmarking Tools

5. Experimental Evaluation and Results
   5.1 Experimental Setup
      5.1.1 Hardware and Software Configuration
      5.1.2 Test Scenarios
      5.1.3 Data Collection Methodology
   5.2 Security Effectiveness Results
      5.2.1 Baseline Connectivity Analysis
      5.2.2 NetworkPolicy Enforcement Results
      5.2.3 CiliumNetworkPolicy L7 Enforcement Results
      5.2.4 Attack Prevention and Detection Rates
   5.3 Performance Evaluation Results
      5.3.1 Network Throughput Comparison
      5.3.2 Latency Measurements
      5.3.3 CPU and Memory Utilization
      5.3.4 Scalability Analysis
   5.4 Observability Results
      5.4.1 Hubble Flow Analysis
      5.4.2 Policy Decision Visibility
      5.4.3 Real-Time Monitoring Capabilities
   5.5 Comparative Analysis
      5.5.1 eBPF vs Traditional iptables
      5.5.2 NetworkPolicy vs CiliumNetworkPolicy
      5.5.3 Performance Overhead Analysis

6. Discussion
   6.1 Security Effectiveness Discussion
   6.2 Performance Implications
   6.3 Practical Deployment Considerations
   6.4 Limitations and Constraints

7. Conclusion
   7.1 Summary of Evaluation
   7.2 Detailed Conclusions
   7.3 Research Contributions

8. Future Work

---

## 1. Introduction

### 1.1 Problem

Kubernetes has become the de facto standard for container orchestration, with multi-tenancy adoption rapidly increasing as organizations seek to optimize infrastructure costs and resource utilization. However, securing multi-tenant Kubernetes clusters presents significant challenges that traditional security mechanisms struggle to address effectively.

**Current Security Gaps:**

1. **Limited Granularity in Network Policies**: Traditional Kubernetes NetworkPolicy operates at Layer 3 (IP) and Layer 4 (port/protocol) only, lacking visibility into application-layer (Layer 7) traffic patterns. This limitation prevents fine-grained control over HTTP methods, API endpoints, and application-specific protocols.

2. **Performance Overhead**: Traditional iptables-based network policies introduce substantial performance overhead, especially at scale. As the number of policies and pods increases, iptables rule chains grow exponentially, leading to increased latency and CPU consumption.

3. **Insufficient Real-Time Observability**: Existing security solutions provide limited real-time visibility into network flows, policy enforcement decisions, and security events. This lack of observability makes it difficult to detect, investigate, and respond to security incidents promptly.

4. **Static Policy Management**: Traditional network policies are static and require manual updates. They cannot adapt dynamically to changing threat landscapes or workload behaviors, limiting their effectiveness in dynamic cloud-native environments.

5. **Cross-Tenant Isolation Challenges**: Ensuring complete isolation between tenants in shared Kubernetes clusters is complex. Misconfigurations, policy gaps, and privilege escalation vulnerabilities can lead to unauthorized cross-tenant access and data breaches.

### 1.2 Motivation

The motivation for this research stems from several critical factors:

**1. Growing Security Concerns in Multi-Tenant Environments**

Multi-tenant Kubernetes deployments are becoming increasingly common, driven by cost optimization and resource efficiency goals. However, this trend amplifies security risks, as a single misconfiguration or vulnerability can compromise multiple tenants. Recent security incidents have highlighted the need for more robust isolation mechanisms.

**2. Performance Requirements in Production Environments**

Production Kubernetes clusters require high-performance networking with minimal latency. Traditional iptables-based solutions become bottlenecks as cluster size grows, impacting application performance and user experience. Organizations need security solutions that do not compromise performance.

**3. Regulatory and Compliance Requirements**

Many industries face strict regulatory requirements for data isolation and security (e.g., GDPR, HIPAA, PCI-DSS). Organizations need demonstrable security controls that provide granular isolation and comprehensive audit trails.

**4. eBPF Technology Maturity**

Extended Berkeley Packet Filter (eBPF) technology has matured significantly, offering kernel-level programmability with safety guarantees. Projects like Cilium have demonstrated the practical viability of eBPF-based security solutions in production environments, making this an opportune time for comprehensive evaluation.

**5. Research Gap**

While eBPF and Cilium have gained adoption, there is limited academic research providing systematic evaluation of their effectiveness for multi-tenant security, particularly with quantitative performance comparisons and comprehensive security testing frameworks.

**Justification for Study:**

This research addresses a critical need by:
- Providing empirical evidence of eBPF-based security effectiveness
- Quantifying performance benefits compared to traditional approaches
- Establishing a reproducible testing framework for multi-tenant security evaluation
- Contributing to the body of knowledge on cloud-native security best practices

### 1.3 Approach

This research employs an **experimental evaluation methodology** to systematically assess eBPF-based security mechanisms (implemented via Cilium) in multi-tenant Kubernetes environments. The approach consists of four main phases:

**Phase 1: Testbed Development**
- Design and implement a multi-tenant Kubernetes testbed using kind (Kubernetes in Docker)
- Deploy Cilium as the Container Network Interface (CNI) with eBPF data plane
- Configure multi-tenant namespaces with RBAC, resource quotas, and network policies
- Integrate Hubble observability for real-time flow analysis

**Phase 2: Baseline Establishment**
- Establish baseline connectivity patterns without security policies
- Measure baseline performance metrics (throughput, latency, resource utilization)
- Document default Kubernetes networking behavior
- Create attack simulation scenarios for security testing

**Phase 3: Security Policy Implementation and Testing**
- Implement traditional Kubernetes NetworkPolicy for tenant isolation
- Implement CiliumNetworkPolicy with L7 enforcement capabilities
- Execute comprehensive attack simulation scenarios:
  - Cross-namespace unauthorized access attempts
  - Unauthorized HTTP method and path access
  - Privilege escalation attempts
  - Host network access attempts
- Measure security effectiveness (detection rate, prevention rate, false positives)

**Phase 4: Performance Benchmarking and Comparative Analysis**
- Measure network throughput using iperf3
- Measure HTTP latency using load testing tools (hey/wrk)
- Monitor CPU and memory utilization
- Compare eBPF-based approach with traditional iptables approach
- Analyze scalability with increasing workload density

**Methodology Characteristics:**
- **Reproducible**: All testbed configurations and test scripts are version-controlled and automated
- **Quantitative**: Results are measured using standardized metrics and tools
- **Comparative**: Direct comparison between traditional and eBPF-based approaches
- **Comprehensive**: Covers security, performance, and observability dimensions

### 1.4 Challenges

#### 1.4.1 Multi-Tenant Isolation Complexity

**Challenge**: Achieving complete isolation between tenants while maintaining operational flexibility is complex. Multiple isolation layers (network, RBAC, resource quotas) must work cohesively, and misconfigurations can create security gaps.

**Impact**: 
- Policy conflicts between different isolation mechanisms
- Difficulty in testing all possible attack vectors
- Ensuring isolation without breaking legitimate inter-tenant communication (if required)

**Mitigation Strategy**:
- Systematic testing of isolation boundaries
- Automated policy validation
- Comprehensive attack simulation covering various scenarios

#### 1.4.2 Performance Overhead Considerations

**Challenge**: Security mechanisms must not significantly impact application performance. Measuring and attributing performance overhead accurately is challenging due to multiple variables (network conditions, workload characteristics, cluster state).

**Impact**:
- Performance measurements may vary across test runs
- Distinguishing between policy enforcement overhead and baseline system overhead
- Ensuring fair comparison between different approaches

**Mitigation Strategy**:
- Multiple test runs with statistical analysis
- Controlled test environment with consistent baseline
- Isolated performance testing separate from security testing

#### 1.4.3 Policy Management and Scalability

**Challenge**: As the number of tenants and policies grows, policy management becomes increasingly complex. Understanding policy interactions, debugging policy decisions, and maintaining policy consistency at scale presents significant challenges.

**Impact**:
- Policy complexity can lead to misconfigurations
- Difficult to trace policy enforcement decisions
- Scalability testing requires significant resources

**Mitigation Strategy**:
- Use observability tools (Hubble) for policy decision visibility
- Automated policy testing and validation
- Incremental scalability testing with controlled growth

#### 1.4.4 Testbed Reproducibility

**Challenge**: Ensuring testbed reproducibility across different environments (local development, CI/CD, cloud) while maintaining consistency in results.

**Impact**:
- Results may vary between environments
- Difficult to validate findings independently

**Mitigation Strategy**:
- Version-controlled configuration files
- Automated setup scripts
- Detailed documentation of environment requirements

### 1.5 Structure of the Dissertation

This dissertation is organized as follows:

**Chapter 2 (Related Works)** reviews existing research and industry practices in container security, Kubernetes multi-tenancy, and eBPF technology. It identifies research gaps and positions this work within the broader context of cloud-native security.

**Chapter 3 (Hypotheses and Evaluation Framework)** presents the research question, proposed hypotheses, and the evaluation framework including security, performance, and observability metrics.

**Chapter 4 (Architecture and Implementation)** describes the testbed architecture, Cilium eBPF implementation details, security policy configurations, and the testing framework developed for this research.

**Chapter 5 (Experimental Evaluation and Results)** presents comprehensive experimental results including security effectiveness, performance benchmarks, observability analysis, and comparative evaluation between eBPF-based and traditional approaches.

**Chapter 6 (Discussion)** provides analysis and interpretation of results, discusses practical implications, limitations, and deployment considerations.

**Chapter 7 (Conclusion)** summarizes the research contributions, key findings, and conclusions drawn from the experimental evaluation.

**Chapter 8 (Future Work)** outlines potential extensions and future research directions.

---

## 2. Related Works

### 2.1 Container Security Evolution

#### 2.1.1 Container Security Challenges

Sultan et al. (2019) identified four critical use cases for container security: image scanning, runtime protection, network segmentation, and compliance monitoring. Their work highlighted the limitations of traditional security approaches in containerized environments, particularly the lack of runtime visibility and the challenges of securing dynamic, ephemeral workloads.

Thompson & Kyer (2025) examined security challenges along the CI/CD pipeline, emphasizing the need for security automation and continuous monitoring. They identified gaps in container security at various stages of the software development lifecycle, particularly in multi-tenant environments where isolation failures can have cascading effects.

**Key Findings:**
- Static security policies are insufficient for dynamic container environments
- Runtime security monitoring is critical but challenging
- Multi-tenant isolation requires multiple defense layers

#### 2.1.2 CI/CD Pipeline Security

The research by Thompson & Kyer (2025) on "Securing the Containerized Environment Along the CI/CD Pipeline" demonstrated that security must be integrated throughout the development lifecycle. They found that post-deployment security measures alone are inadequate, and that security policies must be defined and enforced from the earliest stages of container image creation.

**Relevance to This Research:**
- Validates the need for automated security policy enforcement
- Supports the importance of observability in security operations
- Highlights the complexity of securing multi-stage deployments

#### 2.1.3 Multi-Tenant Security Approaches

Research on multi-tenant Kubernetes security has primarily focused on namespace isolation, RBAC, and network policies. However, most studies have evaluated traditional approaches without comprehensive comparison to emerging eBPF-based solutions.

**Gap Identified:**
- Limited research on eBPF-based multi-tenant security
- Lack of quantitative performance comparisons
- Insufficient real-world attack simulation frameworks

### 2.2 Kubernetes Security Mechanisms

#### 2.2.1 Traditional Network Policies

Kubernetes NetworkPolicy provides L3/L4 network isolation based on pod selectors, namespace selectors, and IP blocks. While effective for basic isolation, NetworkPolicy has several limitations:

- **Lack of L7 Visibility**: Cannot inspect HTTP methods, paths, or application protocols
- **iptables Overhead**: Relies on iptables, which scales poorly with large numbers of policies
- **Limited Observability**: Provides no built-in mechanism for viewing policy enforcement decisions

**Research Findings:**
- NetworkPolicy effectiveness depends heavily on CNI implementation
- Performance degrades significantly with policy complexity
- Debugging policy issues is challenging without observability tools

#### 2.2.2 RBAC and Namespace Isolation

Role-Based Access Control (RBAC) and namespace isolation form the foundation of Kubernetes multi-tenancy. Research has shown that RBAC alone is insufficient for complete tenant isolation, as it primarily controls API access rather than network traffic.

**Limitations:**
- RBAC does not prevent network-level attacks
- Namespace isolation can be bypassed through misconfigurations
- Requires careful policy design and continuous auditing

#### 2.2.3 Service Mesh Security Solutions

Service mesh technologies (Istio, Linkerd) provide L7 security capabilities through sidecar proxies. However, they introduce significant overhead:

- **Resource Consumption**: Sidecar proxies consume CPU and memory for each pod
- **Latency Impact**: Additional network hops increase latency
- **Operational Complexity**: Managing sidecar lifecycle and configuration adds complexity

**Comparison with eBPF Approach:**
- eBPF operates in kernel space, reducing overhead
- No sidecar deployment required
- Simpler operational model

### 2.3 eBPF Technology and Applications

#### 2.3.1 eBPF Fundamentals and Architecture

Extended Berkeley Packet Filter (eBPF) is a kernel technology that allows safe, efficient program execution in the Linux kernel. eBPF programs are:

- **Safe**: Verifier ensures programs cannot crash the kernel
- **Efficient**: JIT compilation for near-native performance
- **Dynamic**: Can be loaded and updated without kernel recompilation

**Key Capabilities:**
- Network packet filtering and manipulation
- System call tracing and security enforcement
- Performance monitoring and observability

#### 2.3.2 eBPF in Cloud-Native Environments

Feng et al. (2024) explored "Enhancing Cloud-Native Security Through eBPF Technology," demonstrating eBPF's potential for security applications. Their work showed that eBPF can provide kernel-level security enforcement with minimal performance overhead compared to user-space solutions.

**Key Contributions:**
- Demonstrated eBPF's effectiveness for security use cases
- Showed performance advantages over traditional approaches
- Identified areas for further research

#### 2.3.3 Cilium: eBPF-Powered CNI

Cilium is a CNI plugin that uses eBPF for networking, security, and observability. Parola et al. (2022) examined "Creating Disaggregated Network Services with eBPF: the Kubernetes Network Provider Use Case," highlighting Cilium's architecture and capabilities.

**Cilium Features Relevant to This Research:**
- **CiliumNetworkPolicy**: Extends Kubernetes NetworkPolicy with L7 capabilities
- **Hubble**: Observability platform for network flows and policy decisions
- **eBPF Data Plane**: Kernel-level networking with high performance
- **Identity-Based Security**: Pod identity tracking for policy enforcement

### 2.4 Summary and Research Gaps

#### 2.4.1 Summary of Progress

Significant progress has been made in:
- Understanding container security challenges
- Developing Kubernetes security mechanisms
- Advancing eBPF technology and applications
- Creating eBPF-based networking solutions (Cilium)

#### 2.4.2 Open Implementation Challenges

**Research Gaps Identified:**

1. **Systematic Multi-Tenant Security Evaluation**: Limited comprehensive evaluation of eBPF-based security for multi-tenant Kubernetes, particularly with quantitative metrics and attack simulation.

2. **Performance Benchmarking**: Insufficient comparative performance analysis between eBPF-based and traditional iptables-based security mechanisms in realistic multi-tenant scenarios.

3. **L7 Policy Effectiveness**: Limited research on the practical effectiveness and overhead of L7 policy enforcement in production-like environments.

4. **Observability Integration**: Incomplete understanding of how observability tools (Hubble) enhance security operations and policy debugging.

5. **Reproducible Testing Frameworks**: Lack of standardized, reproducible testing frameworks for multi-tenant Kubernetes security evaluation.

**This Research Addresses:**
- Comprehensive security effectiveness evaluation
- Quantitative performance comparison
- L7 policy enforcement analysis
- Observability impact assessment
- Reproducible testbed and testing framework

---

## 3. Hypotheses and Evaluation Framework

### 3.1 Research Question

**Primary Research Question:**

*How can eBPF-based security mechanisms, implemented via Cilium, enhance tenant isolation and threat detection in multi-tenant Kubernetes clusters compared to traditional approaches, and what are the performance implications of such implementations?*

**Sub-Questions:**

1. What is the security effectiveness of eBPF-based policies (CiliumNetworkPolicy) compared to traditional NetworkPolicy in preventing cross-tenant attacks?

2. What is the performance overhead of eBPF-based security enforcement compared to iptables-based approaches?

3. How does L7 policy enforcement (HTTP method, path-based) improve security posture compared to L3/L4-only policies?

4. What is the impact of observability tools (Hubble) on security operations and policy debugging?

5. How do eBPF-based solutions scale with increasing numbers of tenants, policies, and workloads?

### 3.2 Proposed Hypotheses

**Hypothesis H1: Security Effectiveness**

*H1: eBPF-based security mechanisms (CiliumNetworkPolicy) provide superior security effectiveness compared to traditional NetworkPolicy, with higher attack prevention rates and lower false positive rates.*

**Rationale**: CiliumNetworkPolicy offers L7 enforcement capabilities and identity-based security, enabling more granular and accurate policy enforcement.

**Hypothesis H2: Performance Efficiency**

*H2: eBPF-based security enforcement introduces lower performance overhead than traditional iptables-based approaches, maintaining higher network throughput and lower latency.*

**Rationale**: eBPF programs run in kernel space with JIT compilation, avoiding the overhead of user-space processing and complex iptables rule chains.

**Hypothesis H3: L7 Policy Value**

*H3: L7 policy enforcement (HTTP method, path-based) significantly improves security posture by preventing application-layer attacks that L3/L4 policies cannot detect.*

**Rationale**: Many attacks occur at the application layer (unauthorized API access, method abuse), requiring L7 visibility for effective prevention.

**Hypothesis H4: Observability Impact**

*H4: Enhanced observability (Hubble) improves security operations efficiency by providing real-time visibility into policy enforcement decisions and network flows.*

**Rationale**: Observability tools enable faster incident detection, policy debugging, and security analysis.

**Hypothesis H5: Scalability**

*H5: eBPF-based solutions scale better than traditional approaches, maintaining consistent performance as the number of policies and workloads increases.*

**Rationale**: eBPF's efficient data structures and kernel-level execution provide better scalability characteristics than iptables rule chains.

### 3.3 Approach for Validating the Hypothesis

**Validation Methodology:**

1. **Controlled Experiments**: Systematic testing in controlled testbed environment
2. **Comparative Analysis**: Direct comparison between eBPF-based and traditional approaches
3. **Quantitative Metrics**: Standardized metrics for security and performance
4. **Statistical Analysis**: Multiple test runs with statistical significance testing
5. **Attack Simulation**: Comprehensive attack scenarios covering various threat vectors

**Experimental Design:**

- **Independent Variables**: Security mechanism type (eBPF vs iptables), policy type (L3/L4 vs L7), workload density
- **Dependent Variables**: Attack prevention rate, network throughput, latency, CPU/memory utilization, policy enforcement accuracy
- **Control Variables**: Cluster configuration, workload characteristics, network conditions

### 3.4 Evaluation Metrics

#### 3.4.1 Security Effectiveness Metrics

**Attack Prevention Rate (APR)**
```
APR = (Number of Attacks Blocked / Total Attack Attempts) × 100
```

**False Positive Rate (FPR)**
```
FPR = (Number of Legitimate Requests Blocked / Total Legitimate Requests) × 100
```

**Detection Rate (DR)**
```
DR = (Number of Attacks Detected / Total Attack Attempts) × 100
```

**Policy Enforcement Accuracy (PEA)**
```
PEA = (Correct Policy Decisions / Total Policy Decisions) × 100
```

**Response Time**
- Time from attack attempt to policy enforcement decision
- Measured in milliseconds

#### 3.4.2 Performance Metrics

**Network Throughput**
- Measured in Mbits/sec or Gbits/sec using iperf3
- Comparison: baseline vs with policies, eBPF vs iptables

**Latency**
- End-to-end request latency (p50, p95, p99 percentiles)
- Measured using HTTP load testing tools (hey/wrk)

**CPU Utilization**
- Percentage of CPU used by security enforcement components
- Measured for Cilium agents and network policy enforcement

**Memory Utilization**
- RAM consumption of security components
- Measured in MB or GB

**Scalability Metrics**
- Performance degradation rate with increasing workload
- Policy processing time as function of policy count

#### 3.4.3 Observability Metrics

**Flow Visibility**
- Number of flows captured and analyzed
- Flow log completeness

**Policy Decision Visibility**
- Percentage of policy decisions logged and traceable
- Time to trace policy decision for a given flow

**Real-Time Monitoring Capability**
- Latency of observability data availability
- Query performance for flow analysis

---

## 4. Architecture and Implementation

### 4.1 Testbed Design

#### 4.1.1 Cluster Architecture

**Cluster Configuration:**
- **Platform**: kind (Kubernetes in Docker) for local development and testing
- **Node Count**: 3 nodes (1 control-plane, 2 worker nodes)
- **Kubernetes Version**: v1.28+
- **Container Runtime**: Docker (via kind)
- **CNI**: Cilium (eBPF-based)

**Rationale for kind:**
- Reproducible local testing environment
- Easy cluster creation and teardown
- Suitable for development and initial evaluation
- Can be extended to cloud environments (EKS) for production-like testing

#### 4.1.2 Multi-Tenant Environment Configuration

**Tenant Namespaces:**
- `tenant-a`: First tenant namespace
- `tenant-b`: Second tenant namespace
- `platform-tools`: Shared platform services namespace

**Isolation Mechanisms:**
1. **Namespace Isolation**: Separate namespaces for each tenant
2. **RBAC**: Role-based access control per tenant
3. **Resource Quotas**: CPU and memory limits per tenant
4. **Network Policies**: Network-level isolation
5. **CiliumNetworkPolicy**: eBPF-based L7 policies

**Workload Configuration:**
- Each tenant runs nginx-based web applications
- Services exposed via ClusterIP
- ConfigMaps for application configuration
- Replica sets for high availability

#### 4.1.3 Network Topology

**Network Architecture:**
- Pod-to-pod communication within same namespace
- Pod-to-service communication via ClusterIP
- Cross-namespace communication (controlled by policies)
- External access (if required for testing)

**Policy Enforcement Points:**
- Ingress policies: Control incoming traffic to pods
- Egress policies: Control outgoing traffic from pods
- L7 policies: HTTP method and path-based enforcement

### 4.2 Cilium eBPF Implementation

#### 4.2.1 Cilium Installation and Configuration

**Installation Method:**
- Cilium CLI for automated installation
- Detects kind cluster and applies appropriate configuration
- Replaces kube-proxy with eBPF-based implementation

**Configuration Parameters:**
- eBPF data plane enabled
- Hubble observability enabled
- Policy enforcement mode: default (allow by default, deny by policy)
- Identity-based security enabled

#### 4.2.2 eBPF Program Deployment

**eBPF Programs Used:**
- **Network Policy Enforcement**: Kernel-level policy checking
- **Load Balancing**: eBPF-based service load balancing
- **Network Observability**: Flow tracking and analysis
- **L7 Proxy**: HTTP-aware policy enforcement (when L7 policies applied)

**Program Lifecycle:**
- Programs loaded at Cilium agent startup
- Dynamically updated when policies change
- Verified by kernel eBPF verifier for safety

#### 4.2.3 Hubble Observability Setup

**Hubble Components:**
- **Hubble Relay**: Aggregates flow data from all nodes
- **Hubble UI**: Web-based flow visualization
- **Hubble CLI**: Command-line flow analysis tool

**Observability Features:**
- Real-time flow logs
- Policy decision visibility
- Service map visualization
- Flow filtering and querying

### 4.3 Security Policy Implementation

#### 4.3.1 Traditional NetworkPolicy Configuration

**NetworkPolicy Example:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-ns
  namespace: tenant-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kube-namespace: tenant-a
```

**Characteristics:**
- L3/L4 enforcement only
- Namespace-based isolation
- Applied to all pods in namespace

#### 4.3.2 CiliumNetworkPolicy L7 Enforcement

**CiliumNetworkPolicy Example:**
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: tenant-a-l7
  namespace: tenant-a
spec:
  endpointSelector:
    matchLabels:
      app: web-a
  ingress:
  - fromEntities:
    - cluster
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
      rules:
        http:
        - method: "GET"
          path: "/status"
```

**Characteristics:**
- L7 HTTP method and path enforcement
- Identity-based policy matching
- Fine-grained access control

#### 4.3.3 RBAC and Resource Quotas

**RBAC Configuration:**
- ServiceAccount per tenant
- Role with namespace-scoped permissions
- RoleBinding linking ServiceAccount to Role

**Resource Quotas:**
- CPU limits: 4 cores per tenant
- Memory limits: 8GB per tenant
- Pod count limits: 10 pods per tenant

### 4.4 Testing Framework

#### 4.4.1 Connectivity Testing

**Test Scenarios:**
1. Pod-to-service within same namespace
2. Pod-to-service across namespaces
3. DNS resolution testing
4. Baseline connectivity (no policies)
5. Connectivity with NetworkPolicy applied
6. Connectivity with CiliumNetworkPolicy applied

**Tools:**
- `curl` for HTTP connectivity testing
- `nslookup` for DNS testing
- Custom test scripts for automation

#### 4.4.2 Attack Simulation Framework

**Attack Scenarios:**
1. **Cross-namespace unauthorized access**: Attempt to access tenant-a from tenant-b
2. **Unauthorized HTTP method**: POST request to GET-only endpoint
3. **Unauthorized path access**: Access to /api instead of /status
4. **Host network privilege escalation**: Deploy pod with hostNetwork=true
5. **Service account token access**: Attempt cross-namespace access using service account

**Implementation:**
- Automated attack scripts
- Expected vs actual results comparison
- Hubble flow analysis for attack detection

#### 4.4.3 Performance Benchmarking Tools

**Network Throughput:**
- **Tool**: iperf3
- **Method**: Server in tenant-a, client in tenant-b
- **Metrics**: Throughput in Mbits/sec, packet loss

**HTTP Latency:**
- **Tool**: hey or wrk (if available), otherwise curl
- **Method**: Load testing with concurrent requests
- **Metrics**: p50, p95, p99 latency, requests per second

**Resource Utilization:**
- **Tool**: kubectl top, Prometheus metrics
- **Method**: Continuous monitoring during tests
- **Metrics**: CPU %, Memory MB, network I/O

**Scalability Testing:**
- Incremental workload increase
- Policy count scaling
- Performance degradation measurement

---

## 5. Experimental Evaluation and Results

### 5.1 Experimental Setup

#### 5.1.1 Hardware and Software Configuration

**Hardware:**
- CPU: Multi-core processor (specify actual specs)
- RAM: 16GB+ (specify actual)
- Storage: SSD
- OS: Ubuntu 22.04 LTS

**Software:**
- Docker: [version]
- Kubernetes: [version via kind]
- Cilium: [version]
- Hubble: [version]

#### 5.1.2 Test Scenarios

**Scenario 1: Baseline (No Policies)**
- Objective: Establish baseline connectivity and performance
- Policies: None
- Tests: Connectivity, performance benchmarks

**Scenario 2: Traditional NetworkPolicy**
- Objective: Evaluate traditional NetworkPolicy effectiveness
- Policies: Kubernetes NetworkPolicy
- Tests: Security, performance comparison

**Scenario 3: CiliumNetworkPolicy L7**
- Objective: Evaluate eBPF-based L7 policy enforcement
- Policies: CiliumNetworkPolicy with HTTP rules
- Tests: Security effectiveness, L7 enforcement, performance

**Scenario 4: Attack Simulation**
- Objective: Test security against various attack vectors
- Policies: Various (baseline, NetworkPolicy, CiliumNetworkPolicy)
- Tests: Attack prevention, detection rates

#### 5.1.3 Data Collection Methodology

**Data Collection:**
- Automated test execution with logging
- Hubble flow export (JSON format)
- Prometheus metrics scraping (if available)
- kubectl top snapshots
- Test result logs with timestamps

**Data Storage:**
- Results directory with timestamped files
- Separate files for each test scenario
- JSON exports for programmatic analysis

### 5.2 Security Effectiveness Results

#### 5.2.1 Baseline Connectivity Analysis

[Results from connectivity tests showing default Kubernetes behavior]

**Findings:**
- Cross-namespace communication allowed by default
- Pod-to-service communication works within and across namespaces
- DNS resolution functional

#### 5.2.2 NetworkPolicy Enforcement Results

[Results showing NetworkPolicy effectiveness]

**Metrics:**
- Attack Prevention Rate: [X]%
- False Positive Rate: [X]%
- Policy Enforcement Accuracy: [X]%

**Findings:**
- NetworkPolicy successfully blocks cross-namespace traffic
- Same-namespace traffic allowed
- L3/L4 enforcement effective for basic isolation

#### 5.2.3 CiliumNetworkPolicy L7 Enforcement Results

[Results showing L7 policy effectiveness]

**Metrics:**
- L7 Attack Prevention Rate: [X]%
- HTTP Method Enforcement: [X]% accuracy
- Path-Based Enforcement: [X]% accuracy

**Findings:**
- L7 policies successfully block unauthorized HTTP methods
- Path-based access control effective
- Application-layer attacks prevented that L3/L4 policies cannot detect

#### 5.2.4 Attack Prevention and Detection Rates

[Comprehensive attack simulation results]

**Attack Prevention Matrix:**

| Attack Type | Baseline | NetworkPolicy | CiliumNetworkPolicy L7 |
|------------|----------|---------------|------------------------|
| Cross-namespace access | ❌ Allowed | ✅ Blocked | ✅ Blocked |
| Unauthorized HTTP method | ❌ Allowed | ❌ Allowed | ✅ Blocked |
| Unauthorized path | ❌ Allowed | ❌ Allowed | ✅ Blocked |
| Host network access | ⚠️ Created | ⚠️ Created | ⚠️ Created* |

*Requires additional host firewall policies

### 5.3 Performance Evaluation Results

#### 5.3.1 Network Throughput Comparison

[Throughput measurements]

**Results:**
- Baseline throughput: [X] Gbits/sec
- With NetworkPolicy: [X] Gbits/sec ([X]% overhead)
- With CiliumNetworkPolicy: [X] Gbits/sec ([X]% overhead)

**Analysis:**
- eBPF-based approach shows [X]% better throughput than iptables
- Overhead is minimal and acceptable for production use

#### 5.3.2 Latency Measurements

[Latency measurements]

**Results:**
- Baseline p95 latency: [X]ms
- With NetworkPolicy: [X]ms ([X]% increase)
- With CiliumNetworkPolicy: [X]ms ([X]% increase)

**Analysis:**
- Latency impact is minimal
- L7 enforcement adds [X]ms overhead but provides significant security value

#### 5.3.3 CPU and Memory Utilization

[Resource utilization measurements]

**Results:**
- Cilium agent CPU: [X]%
- Cilium agent Memory: [X]MB
- Policy enforcement overhead: [X]% CPU

**Analysis:**
- Resource consumption is reasonable
- eBPF approach more efficient than sidecar-based solutions

#### 5.3.4 Scalability Analysis

[Scalability test results]

**Results:**
- Performance with 10 policies: [X]
- Performance with 50 policies: [X]
- Performance with 100 policies: [X]

**Analysis:**
- eBPF scales better than iptables with policy count
- Performance degradation is linear and acceptable

### 5.4 Observability Results

#### 5.4.1 Hubble Flow Analysis

[Flow analysis results]

**Findings:**
- [X] flows captured during testing
- Policy decisions visible in flow logs
- Real-time flow analysis enabled

#### 5.4.2 Policy Decision Visibility

[Policy decision visibility analysis]

**Findings:**
- 100% of policy decisions traceable
- Flow-to-policy mapping available
- Debugging time reduced significantly

#### 5.4.3 Real-Time Monitoring Capabilities

[Real-time monitoring analysis]

**Findings:**
- Hubble UI provides immediate flow visualization
- CLI enables quick flow querying
- Policy debugging significantly improved

### 5.5 Comparative Analysis

#### 5.5.1 eBPF vs Traditional iptables

**Performance Comparison:**

| Metric | iptables | eBPF (Cilium) | Improvement |
|--------|----------|---------------|-------------|
| Throughput | [X] Gbps | [X] Gbps | [X]% |
| Latency (p95) | [X]ms | [X]ms | [X]% |
| CPU Overhead | [X]% | [X]% | [X]% |

**Security Comparison:**
- eBPF provides L7 capabilities not available in iptables
- Identity-based security more accurate
- Better observability

#### 5.5.2 NetworkPolicy vs CiliumNetworkPolicy

**Feature Comparison:**

| Feature | NetworkPolicy | CiliumNetworkPolicy |
|---------|---------------|---------------------|
| L3/L4 Enforcement | ✅ | ✅ |
| L7 Enforcement | ❌ | ✅ |
| Identity-Based | ❌ | ✅ |
| Observability | Limited | Excellent |

**Security Effectiveness:**
- CiliumNetworkPolicy prevents [X]% more attack types
- L7 enforcement critical for application-layer security

#### 5.5.3 Performance Overhead Analysis

[Detailed overhead analysis]

**Key Findings:**
- eBPF overhead is minimal and acceptable
- L7 enforcement adds [X]ms latency but provides significant security value
- Overall performance impact is justified by security benefits

---

## 6. Discussion

### 6.1 Security Effectiveness Discussion

[Analysis of security results]

**Key Insights:**
- eBPF-based policies provide superior security through L7 enforcement
- Identity-based security more accurate than IP-based
- Observability significantly improves security operations

**Implications:**
- Organizations should consider eBPF-based solutions for multi-tenant security
- L7 policies essential for application-layer security
- Observability tools critical for effective security operations

### 6.2 Performance Implications

[Analysis of performance results]

**Key Insights:**
- eBPF provides better performance than iptables
- Overhead is minimal and acceptable
- Performance benefits justify security implementation

**Implications:**
- No significant performance penalty for enhanced security
- Suitable for production environments
- Better scalability characteristics

### 6.3 Practical Deployment Considerations

[Practical considerations]

**Deployment Factors:**
- Cilium requires kernel support (Linux 4.9.17+)
- Initial setup complexity vs long-term benefits
- Team training requirements
- Integration with existing tooling

**Recommendations:**
- Start with L3/L4 policies, gradually adopt L7
- Invest in observability tooling
- Establish policy management practices

### 6.4 Limitations and Constraints

**Research Limitations:**
- Local testbed may not reflect all production scenarios
- Limited to specific Kubernetes version and Cilium version
- Attack scenarios may not cover all possible vectors

**Future Work Needed:**
- Cloud environment testing (EKS, GKE)
- Larger scale testing
- Additional attack scenarios
- Long-term stability testing

---

## 7. Conclusion

### 7.1 Summary of Evaluation

This research systematically evaluated eBPF-based security mechanisms (implemented via Cilium) for multi-tenant Kubernetes clusters. Through comprehensive experimental evaluation, we compared eBPF-based approaches with traditional iptables-based solutions across security effectiveness, performance, and observability dimensions.

**Key Evaluations Conducted:**
1. Security effectiveness: Attack prevention, detection rates, policy enforcement accuracy
2. Performance: Throughput, latency, resource utilization, scalability
3. Observability: Flow visibility, policy decision tracing, real-time monitoring

### 7.2 Detailed Conclusions

**Conclusion 1: Security Effectiveness**

eBPF-based security mechanisms, specifically CiliumNetworkPolicy with L7 enforcement, provide superior security effectiveness compared to traditional NetworkPolicy. The ability to enforce HTTP method and path-based policies enables prevention of application-layer attacks that L3/L4 policies cannot address. Identity-based security provides more accurate policy enforcement than IP-based approaches.

**Conclusion 2: Performance Efficiency**

eBPF-based security enforcement demonstrates superior performance characteristics compared to traditional iptables-based approaches. Throughput is [X]% higher, latency overhead is minimal ([X]ms), and CPU utilization is lower. The kernel-level execution and efficient data structures enable better scalability as policy count increases.

**Conclusion 3: Observability Value**

Enhanced observability through Hubble significantly improves security operations. Real-time flow visibility, policy decision tracing, and comprehensive flow analysis enable faster incident detection, policy debugging, and security analysis. The observability capabilities justify the additional complexity.

**Conclusion 4: Practical Viability**

eBPF-based security solutions are viable for production multi-tenant Kubernetes deployments. The combination of enhanced security, acceptable performance overhead, and excellent observability makes Cilium a compelling choice for organizations requiring robust multi-tenant isolation.

**Conclusion 5: Research Contribution**

This research provides empirical evidence and quantitative analysis of eBPF-based security effectiveness, contributing to the body of knowledge on cloud-native security. The reproducible testbed and testing framework enable future research and industry adoption.

### 7.3 Research Contributions

**Contribution 1: Systematic Evaluation Framework**

Developed a comprehensive, reproducible testing framework for evaluating multi-tenant Kubernetes security. The framework includes automated testbed setup, security testing scenarios, performance benchmarking, and results collection.

**Contribution 2: Quantitative Performance Analysis**

Provided quantitative comparison between eBPF-based and traditional iptables-based security mechanisms, demonstrating performance advantages of eBPF approach with empirical data.

**Contribution 3: L7 Policy Effectiveness Analysis**

Evaluated the practical effectiveness and overhead of L7 policy enforcement in realistic multi-tenant scenarios, providing insights for organizations considering L7 security policies.

**Contribution 4: Observability Impact Assessment**

Analyzed the impact of observability tools (Hubble) on security operations, demonstrating significant improvements in policy debugging and incident response.

**Contribution 5: Reproducible Research Artifacts**

Created version-controlled, automated testbed and testing framework that enables reproducible research and industry adoption.

---

## 8. Future Work

### 8.1 Extended Testing Scenarios

**Cloud Environment Testing:**
- Deploy testbed to AWS EKS for production-like evaluation
- Test in multi-AZ deployments
- Evaluate cloud-specific security features

**Additional Attack Vectors:**
- Advanced persistent threats (APTs)
- Container escape attempts
- Supply chain attacks
- Zero-day exploit simulation

### 8.2 Scalability and Performance

**Large-Scale Testing:**
- Test with 100+ tenants
- Evaluate with 1000+ policies
- Performance testing with high workload density

**Long-Term Stability:**
- Extended duration testing (weeks/months)
- Resource leak detection
- Policy update performance

### 8.3 Advanced Security Features

**Machine Learning Integration:**
- Anomaly detection using flow data
- Automated policy generation
- Threat intelligence integration

**Multi-Cluster Security:**
- Cross-cluster policy enforcement
- Centralized policy management
- Multi-cluster observability

### 8.4 Policy Management

**Policy Authoring Tools:**
- Visual policy editor
- Policy templates and best practices
- Policy validation and testing tools

**Policy Lifecycle Management:**
- Version control for policies
- Policy rollback mechanisms
- Automated policy testing

### 8.5 Integration and Automation

**CI/CD Integration:**
- Policy-as-code workflows
- Automated policy testing in pipelines
- Security policy validation gates

**Compliance and Auditing:**
- Compliance policy templates
- Automated compliance checking
- Audit trail generation

---

## References

[To be populated with actual citations from your research papers]

1. Sultan, et al. (2019). Container Security Issues, Challenges and the Road Ahead.
2. Thompson & Kyer (2025). Securing the Containerized Environment Along the CI/CD Pipeline.
3. Feng, et al. (2024). Enhancing Cloud-Native Security Through eBPF Technology.
4. Parola, et al. (2022). Creating Disaggregated Network Services with eBPF: the Kubernetes Network Provider Use Case.
5. Bringhenti, et al. (2023). Security automation for multi-cluster orchestration in Kubernetes.
6. Nguyen & Kim (2022). A Design of Resource Allocation Structure for Multi-Tenant Services in Kubernetes Cluster.
7. [Additional references from your PDF papers]

---

**End of Research Report Structure**

