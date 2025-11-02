# 3-Node Kubernetes Cluster Infrastructure on AWS

A complete, production-ready Kubernetes cluster setup on AWS using Terraform for infrastructure provisioning and Ansible for cluster configuration. This setup creates a self-managed Kubernetes cluster with Calico CNI, NGINX Ingress, storage drivers, and GitOps capabilities.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup Steps](#detailed-setup-steps)
- [Infrastructure Components](#infrastructure-components)
- [Kubernetes Components](#kubernetes-components)
- [Configuration Details](#configuration-details)
- [Accessing the Cluster](#accessing-the-cluster)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                            │
│                                                             │
│  ┌───────────────────────────────────────────────────┐    │
│  │                    VPC                             │    │
│  │                                                     │    │
│  │  ┌──────────────┐  ┌──────────────┐               │    │
│  │  │   Master-1   │  │   Worker-1   │               │    │
│  │  │  (Control    │  │  (Compute +  │               │    │
│  │  │   Plane)     │  │  AWS Loads)  │               │    │
│  │  │              │  │              │               │    │
│  │  │ • etcd       │  │ • NGINX      │               │    │
│  │  │ • API Server │  │ • EBS/EFS   │               │    │
│  │  │ • Scheduler  │  │ • Pods      │               │    │
│  │  │ • Controller │  │              │               │    │
│  │  └──────────────┘  └──────────────┘               │    │
│  │                                                     │    │
│  │  ┌──────────────┐                                 │    │
│  │  │   Worker-2   │                                 │    │
│  │  │  (Compute)   │                                 │    │
│  │  │              │                                 │    │
│  │  │ • Pods       │                                 │    │
│  │  └──────────────┘                                 │    │
│  └───────────────────────────────────────────────────┘    │
│                                                             │
│  ┌───────────────────────────────────────────────────┐    │
│  │              Supporting Services                   │    │
│  │  • S3 (etcd backups)                             │    │
│  │  • EFS (shared storage)                           │    │
│  │  • IAM Roles & Policies                           │    │
│  └───────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## ✅ Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Make** utility installed (for automation)
4. **Ansible** installed (for cluster setup)
5. **AWS Permissions** for EC2, VPC, IAM, S3, and EFS operations

### Installation Instructions

**macOS:**
```bash
brew install ansible terraform
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install make ansible terraform
```

**CentOS/RHEL:**
```bash
sudo yum install make ansible terraform
# or for newer versions:
sudo dnf install make ansible terraform
```

## 🚀 Quick Start

### Complete Setup (Recommended)

```bash
# Step 1: Setup infrastructure (keys + terraform + inventory)
make setup-infra

# Step 2: Edit cluster-setup/inventory/hosts.yml with actual IPs from terraform output
# Step 3: Complete cluster setup with all addons
make setup-cluster
make setup-addons
```

### Step-by-Step Setup

```bash
# Infrastructure
make keys                    # Generate SSH key pair
make deploy-infrastructure   # Deploy VPC and EC2 instances
make inventory              # Create inventory file template

# Edit cluster-setup/inventory/hosts.yml with actual IPs

# Cluster Setup
make ping                   # Test connectivity
make prereq                 # Verify prerequisites & configure kubelet
make hostnames              # Configure hostnames
make master                 # Initialize master node
make cni                    # Install Calico CNI
make workers                # Join worker nodes
make verify                 # Verify cluster
make kubectl-setup          # Setup kubectl autocomplete

# Addons
make label-worker1          # Label worker1 for AWS workloads
make nginx-ingress          # Install NGINX Ingress Controller
make ebs-csi                # Install EBS CSI Driver
make efs-csi                # Install EFS CSI Driver
make cert-manager           # Install Cert Manager
make cluster-issuer         # Create Let's Encrypt ClusterIssuer
make metrics-server         # Install Metrics Server
make argocd                 # Install ArgoCD
make argocd-ingress         # Create ArgoCD Ingress
make argocd-vprofile        # Create ArgoCD VProfile app
make vprofile-ingress       # Create VProfile Ingress
```

## 📚 Detailed Setup Steps

### Phase 1: Infrastructure Provisioning (Terraform)

#### 1.1 S3 Backend Setup
- Creates S3 bucket for Terraform state management
- Enables versioning and encryption
- Blocks public access

#### 1.2 VPC Infrastructure
- Creates VPC with public subnets
- Configures Internet Gateway
- Sets up route tables

#### 1.3 EC2 Instances
- **Master Node**: 1x t3.medium instance
  - Public IP enabled
  - IAM Role: `etcd_backup` (includes AWS Load Balancer Controller, EBS/EFS CSI policies)
  - Security Group: Allows SSH, Kubernetes API, kubelet, and VPC CIDR for pod-to-pod communication
  
- **Worker Nodes**: 2x t3.medium instances
  - Public IP enabled
  - Worker1 IAM Role: `aws_workloads` (includes AWS Load Balancer Controller, EBS/EFS CSI policies)
  - Worker2 IAM Role: None (no IAM instance profile)
  - Security Group: Allows SSH, HTTP/HTTPS from internet (0.0.0.0/0), kubelet from masters, NodePort range from VPC

#### 1.4 Security Groups

**Master Security Group:**
- SSH (22): Internet (0.0.0.0/0)
- Kubernetes API (6443): Internet (0.0.0.0/0)
- etcd (2379-2380): VPC CIDR
- kubelet (10250): Workers
- Controller Manager (10257): VPC CIDR
- Scheduler (10259): VPC CIDR
- HTTP/HTTPS (80/443): VPC CIDR only (for pod-to-pod communication)

**Worker Security Group:**
- SSH (22): Internet (0.0.0.0/0)
- HTTP (80): Internet (0.0.0.0/0) - **For NGINX Ingress access**
- HTTPS (443): Internet (0.0.0.0/0) - **For NGINX Ingress access**
- kubelet (10250): Masters only
- NodePort (30000-32767): VPC CIDR
- All traffic from masters
- Pod-to-pod communication: VPC CIDR + Calico Pod CIDR (192.168.0.0/16)

#### 1.5 IAM Configuration

**Master Node IAM Role (`etcd_backup`):**
- etcd backup policy (S3 access)
- AWS Load Balancer Controller policy
- EBS CSI Driver policy
- EFS CSI Driver policy

**Worker1 IAM Role (`aws_workloads`):**
- AWS Load Balancer Controller policy
- EBS CSI Driver policy
- EFS CSI Driver policy
- etcd backup policy

**Worker2 IAM Role:**
- None (no IAM instance profile attached)

#### 1.6 Additional Resources
- S3 bucket for etcd backups
- EFS file system for shared storage
- IAM roles and instance profiles
- Security groups with proper rules

### Phase 2: Node Configuration (Userdata Scripts)

#### 2.1 System Preparation
- System updates and package installation
- Hostname configuration
- Swap disabled
- Kernel modules loaded (br_netfilter)
- IP forwarding enabled

#### 2.2 Container Runtime
- Containerd installation and configuration
- SystemdCgroup enabled

#### 2.3 Kubernetes Packages
- kubelet, kubeadm, kubectl installation
- Kubernetes packages pinned to prevent auto-updates

**Note**: Kubelet configuration with public IP is done in Ansible playbook (not userdata)

### Phase 3: Kubernetes Cluster Setup (Ansible)

#### 3.1 Prerequisites Verification (`01-verify-prerequisites.yml`)
- Tests connectivity to all nodes
- Verifies containerd is running
- Checks kubelet, kubeadm, kubectl versions
- Verifies swap is disabled
- Loads br_netfilter module
- Enables IP forwarding and bridge netfilter
- **Configures kubelet extra args**: Sets `--node-ip` to each node's public IP address
- Reloads systemd and restarts kubelet

#### 3.2 Hostname Configuration (`02-configure-hostnames.yml`)
- Sets hostnames: `master1`, `worker1`, `worker2`
- Updates `/etc/hosts` file on all nodes

#### 3.3 Master Node Initialization (`03-initi-master.yml`)
- Resets any previous kubeadm state
- Initializes Kubernetes control plane with `kubeadm init --pod-network-cidr=192.168.0.0/16`
- Configures kubectl for root and ubuntu users
- Sets KUBECONFIG environment variable

#### 3.4 CNI Installation (`04-install-cni.yml`)
- Installs **Calico CNI** using official manifest
- Configures pod networking with CIDR `192.168.0.0/16`
- Waits for Calico pods to be running

#### 3.5 Worker Node Joining (`05-join-workers.yml`)
- Retrieves join command from master node
- Joins worker1 and worker2 to the cluster
- Waits for nodes to be ready

#### 3.6 Cluster Verification (`06-verify-cluster.yml`)
- Verifies all nodes are Ready
- Checks system pods are running
- Creates and verifies test pod

#### 3.7 Kubectl Setup (`07-setup-kubectl-autocomplete.yml`)
- Configures kubectl bash completion
- Creates alias `k` for `kubectl`
- Sets up persistent configuration

#### 3.8 Worker Node Labeling (`08-label-worker1.yml`)
- Labels `worker1` with `aws-workloads=enabled`
- Used for node affinity/selector for AWS-dependent workloads

### Phase 4: Addon Components

#### 4.1 NGINX Ingress Controller (`10-install-nginx-ingress.yml`)
- Installs NGINX Ingress Controller via Helm
- **Configuration** (`values/nginx-ingress.yaml`):
  - Service Type: `NodePort` (no AWS Load Balancer)
  - hostPort enabled: Binds directly to ports 80 and 443 on worker nodes
  - NodeSelector: `aws-workloads=enabled` (runs on worker1)
  - Access: Direct via worker node public IPs on ports 80/443

#### 4.2 EBS CSI Driver (`11-install-ebs-csi-driver.yml`)
- Installs AWS EBS CSI Driver via Helm
- Creates StorageClass: `ebs-gp3`
- Uses IAM instance profile from worker1 (no separate IAM role)
- Allows dynamic provisioning of EBS volumes

#### 4.3 EFS CSI Driver (`12-install-efs-csi-driver.yml`)
- Installs AWS EFS CSI Driver via Helm
- Creates StorageClass: `efs`
- Uses EFS file system ID from Terraform outputs
- Allows dynamic provisioning of EFS mounts

#### 4.4 Cert Manager (`13-install-cert-manager.yml`)
- Installs Cert Manager via Helm
- Sets up CRDs for certificate management

#### 4.5 ClusterIssuer (`14-create-cluster-issuer.yml`)
- Creates Let's Encrypt ClusterIssuer
- Configured for HTTP-01 challenge
- Email: `ochuko@gmail.com` (configurable in `vars/main.yml`)

#### 4.6 Metrics Server (`15-install-metrics-server.yml`)
- Installs Metrics Server via Helm
- Configured with proper health checks
- Enables `kubectl top` commands

#### 4.7 ArgoCD (`16-install-argocd.yml`)
- Installs ArgoCD via Helm
- **Configuration** (`values/argocd-values.yml`):
  - Server insecure mode: `true` (for TLS-terminated ingress)
  - Environment variable: `ARGOCD_SERVER_INSECURE=true`
  - Service Type: `ClusterIP`
  - Ingress: Disabled (created separately)

#### 4.8 ArgoCD Ingress (`17-create-argocd-ingress.yml`)
- Creates ArgoCD Ingress resource
- Domain: `argo.ochukowhoro.xyz`
- TLS: Managed by Cert Manager
- Ingress Class: `external-nginx`

#### 4.9 ArgoCD VProfile Application (`18-create-argocd-vprofile.yml`)
- Creates ArgoCD AppProject: `vprofile`
- Creates ArgoCD Application: `vprofile-app`
- Automated sync enabled

#### 4.10 VProfile Ingress (`19-create-vprofile-ingress.yml`)
- Creates VProfile Ingress resource
- Domain: `vprofile.ochukowhoro.xyz`
- TLS: Managed by Cert Manager

## 🛠️ Infrastructure Components

### Terraform Modules

1. **S3 Backend** (`global/s3-state/`)
   - Terraform state storage
   - Versioning and encryption enabled

2. **VPC** (`staging/vpc/`)
   - VPC with public subnets
   - Internet Gateway
   - Route tables

3. **K8s Cluster** (`staging/k8s-cluster/`)
   - EC2 instances (master + workers)
   - Security groups
   - IAM roles and instance profiles
   - S3 bucket for etcd backups
   - EFS file system

### Security Groups

**Master Nodes:**
- HTTP/HTTPS: VPC CIDR only (pod-to-pod communication)
- SSH: Internet (0.0.0.0/0)
- Kubernetes API: Internet (0.0.0.0/0)
- etcd: VPC CIDR
- kubelet: Workers only

**Worker Nodes:**
- HTTP/HTTPS: **Internet (0.0.0.0/0)** - For NGINX Ingress direct access
- SSH: Internet (0.0.0.0/0)
- kubelet: Masters only
- NodePort: VPC CIDR
- Pod-to-pod: VPC CIDR + Calico Pod CIDR

### IAM Roles

**Master Node (`etcd_backup` role):**
- etcd backup to S3
- AWS Load Balancer Controller (for master node workloads)
- EBS CSI Driver
- EFS CSI Driver

**Worker1 (`aws_workloads` role):**
- AWS Load Balancer Controller
- EBS CSI Driver
- EFS CSI Driver
- etcd backup

**Worker2:**
- No IAM role (no AWS workloads)

## ☸️ Kubernetes Components

### Core Components

- **CNI**: Calico (Pod CIDR: 192.168.0.0/16)
- **Ingress**: NGINX Ingress Controller (NodePort + hostPort mode)
- **Storage**: EBS CSI Driver + EFS CSI Driver
- **Certificates**: Cert Manager + Let's Encrypt
- **Monitoring**: Metrics Server
- **GitOps**: ArgoCD

### Node Configuration

- **Kubelet**: Configured with `--node-ip` set to public IP address
- **Worker1 Label**: `aws-workloads=enabled` (for AWS workload scheduling)

### Storage Classes

- **ebs-gp3**: EBS volumes (GP3 storage class)
- **efs**: EFS file system (shared storage)

### Ingress Configuration

- **NGINX Ingress**: 
  - Service Type: NodePort
  - hostPort: Enabled (ports 80/443)
  - Access: Direct via worker node public IPs
  - No AWS Load Balancer required
  - **DNS Configuration**: Only worker1's public IP needs to be mapped to the hostname since NGINX Ingress runs on worker1

- **ArgoCD Ingress**: 
  - Domain: `argo.ochukowhoro.xyz`
  - TLS: Managed by Cert Manager

- **VProfile Ingress**: 
  - Domain: `vprofile.ochukowhoro.xyz`
  - TLS: Managed by Cert Manager

**Important**: For ingress to work and be verified, you only need to map **worker1's public IP** to the hostname (e.g., `argo.ochukowhoro.xyz`, `vprofile.ochukowhoro.xyz`) in your DNS provider. This is because NGINX Ingress Controller runs exclusively on worker1 due to node affinity (`aws-workloads=enabled`).

Example DNS A record:
- `argo.ochukowhoro.xyz` → `3.90.107.239` (worker1 public IP)
- `vprofile.ochukowhoro.xyz` → `3.90.107.239` (worker1 public IP)

## ⚙️ Configuration Details

### Kubelet Configuration

The kubelet is configured to use each node's **public IP address** as the `--node-ip`. This is done in the prerequisites playbook after all packages are installed:

```yaml
# In 01-verify-prerequisites.yml
- name: Get public IP address
  shell: curl -s http://169.254.169.254/latest/meta-data/public-ipv4
  register: public_ip

- name: Configure kubelet extra args with public IP
  copy:
    content: |
      KUBELET_EXTRA_ARGS="--node-ip={{ public_ip.stdout }}"
    dest: /etc/default/kubelet
```

### NGINX Ingress Configuration

NGINX Ingress is configured to use **NodePort with hostPort mode**, allowing direct access via worker node IPs:

```yaml
# In values/nginx-ingress.yaml
controller:
  service:
    type: NodePort
    nodePorts:
      http: 30080
      https: 30443
  hostPort:
    enabled: true
    ports:
      http: 80
      https: 443
  nodeSelector:
    aws-workloads: enabled
```

**Access**: `http://<worker-node-public-ip>` or `https://<worker-node-public-ip>`

**DNS Configuration**: For ingress to work and be verified with hostname-based routing, you only need to map **worker1's public IP** to the hostname in your DNS provider. This is because NGINX Ingress Controller runs exclusively on worker1 due to node affinity (`aws-workloads=enabled`). Cert Manager will automatically verify domain ownership and issue TLS certificates for the configured hostnames.

### ArgoCD Configuration

ArgoCD server is configured with insecure mode for TLS-terminated ingress:

```yaml
# In values/argocd-values.yml
server:
  insecure: true
  env:
    - name: ARGOCD_SERVER_INSECURE
      value: "true"
```

### Worker Node Labeling

Worker1 is labeled with `aws-workloads=enabled` to schedule AWS-dependent workloads:
- NGINX Ingress Controller
- EBS CSI Driver
- EFS CSI Driver

## 🔐 Accessing the Cluster

### SSH Access

   ```bash
# Get IPs from Terraform output
cd staging/k8s-cluster && terraform output

# SSH to master
ssh -i k8s-cluster-key ubuntu@<master-public-ip>

# SSH to worker1
ssh -i k8s-cluster-key ubuntu@<worker1-public-ip>

# SSH to worker2
ssh -i k8s-cluster-key ubuntu@<worker2-public-ip>
```

### Kubernetes API Access

   ```bash
# From master node
   kubectl get nodes
   kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A
```

### NGINX Ingress Access

Access services via worker node public IPs:
- HTTP: `http://<worker-node-public-ip>`
- HTTPS: `https://<worker-node-public-ip>`

**DNS Configuration for Ingress**:
For ingress to work properly with hostname-based routing, you need to configure DNS A records pointing to **worker1's public IP**:

   ```bash
# Get worker1 public IP
cd staging/k8s-cluster && terraform output -raw worker_public_ips | head -n1

# Configure DNS A records (example):
# argo.ochukowhoro.xyz      →  <worker1-public-ip>
# vprofile.ochukowhoro.xyz  →  <worker1-public-ip>
```

**Important**: Only worker1's public IP needs to be mapped to the hostname because NGINX Ingress Controller runs exclusively on worker1 (due to node affinity). Cert Manager will verify the domain ownership and issue TLS certificates automatically.

### ArgoCD UI Access

- URL: `https://argo.ochukowhoro.xyz`
- TLS: Managed by Cert Manager
- Get initial admin password:
   ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

## 🐛 Troubleshooting

### Check Node Status
   ```bash
kubectl get nodes
kubectl describe node <node-name>
   ```

### Check Pod Status
   ```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
   ```

### Check Kubelet Configuration
   ```bash
# On each node
cat /etc/default/kubelet
systemctl status kubelet
journalctl -u kubelet -n 50
   ```

### Check Network Connectivity
   ```bash
# Test connectivity from Ansible
ansible all -m ping

# Check Calico pods
kubectl get pods -n kube-system -l k8s-app=calico-node
```

### Common Issues

1. **Nodes not joining**: Check kubelet status and join token
2. **Pods not starting**: Verify CNI is installed and running
3. **Ingress not accessible**: 
   - Check security groups allow HTTP/HTTPS from internet on worker nodes
   - Verify DNS A record points to **worker1's public IP** (not master or worker2)
   - Ensure NGINX Ingress pods are running on worker1: `kubectl get pods -n ingress-nginx -o wide`
4. **TLS certificates not issued**: 
   - Verify DNS A record points to worker1's public IP
   - Check Cert Manager pods are running: `kubectl get pods -n cert-manager`
   - Check Certificate resources: `kubectl get certificates -A`
   - View Certificate events: `kubectl describe certificate <cert-name> -n <namespace>`
5. **Storage issues**: Verify IAM roles have correct permissions

## 🧹 Cleanup

### Quick Reset (Keeps Infrastructure)
```bash
make cleanup-cluster
```

### Complete Cleanup
```bash
make clean              # Clean local files + reset cluster
make destroy-infrastructure  # Destroy AWS infrastructure
```

### Step-by-Step Cleanup

```bash
# 1. Clean Kubernetes resources
make cleanup-cluster

# 2. Clean local files
make clean

# 3. Destroy infrastructure
make destroy-infrastructure
```

## 📝 Key Decisions and Rationale

### Why Calico CNI?
- Works well with self-managed clusters
- No AWS-specific dependencies
- Simple configuration
- Pod CIDR: 192.168.0.0/16

### Why No AWS Load Balancer Controller?
- We're using NGINX Ingress with direct node access (hostPort mode)
- No need for AWS NLB/ALB
- Simpler architecture
- Lower cost (no load balancer charges)

### Why Public IPs for Kubelet?
- Enables direct access to services via worker node IPs
- Simplifies networking configuration
- Works well with hostPort mode for NGINX Ingress

### Why Worker1 Only for AWS Workloads?
- Worker1 has IAM instance profile with AWS permissions
- Worker2 has no IAM role (cost optimization)
- Node affinity ensures AWS workloads only run on worker1

### Why hostPort Mode for NGINX?
- Allows direct access on standard ports (80/443)
- No need for AWS Load Balancer
- Simpler configuration
- Lower cost

## 📊 Makefile Targets Summary

### Infrastructure
- `make setup-infra` - Complete infrastructure setup
- `make deploy-infrastructure` - Deploy VPC and K8s cluster
- `make destroy-infrastructure` - Destroy all infrastructure

### Cluster Setup
- `make setup-cluster` - Complete cluster setup (all playbooks)
- `make all` - Run all core + addon playbooks

### Addons
- `make setup-addons` - Install all addons
- Individual targets: `nginx-ingress`, `ebs-csi`, `efs-csi`, `cert-manager`, `metrics-server`, `argocd`

### Cleanup
- `make cleanup-cluster` - Reset Kubernetes cluster
- `make clean` - Clean local files + reset cluster
- `make destroy-infrastructure` - Destroy AWS resources

## 🔗 Useful Commands

   ```bash
# View all Terraform outputs
cd staging/k8s-cluster && terraform output

# Check cluster status
   kubectl get nodes
   kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# View NGINX Ingress service
kubectl get svc -n ingress-nginx

# Check node labels
kubectl get nodes --show-labels
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Calico CNI Documentation](https://docs.tigera.io/calico/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Cert Manager Documentation](https://cert-manager.io/docs/)

---

**Last Updated**: Configuration uses Calico CNI, NGINX Ingress with hostPort mode, and direct worker node access (no AWS Load Balancer).
