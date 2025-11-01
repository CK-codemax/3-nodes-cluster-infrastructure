# 3-Node Kubernetes Infrastructure Setup on AWS

This setup creates a 3 node kubernetes cluster using kubeadm on AWS. The process is fully automated using Terraform for provisioning Infrastructure and ansible for automating kubernetes setup.

## ✅ Cluster Status - WORKING!

**Successfully tested and verified:**
- **3 nodes**: master1 (Ready), worker1 (Ready), worker2 (Ready)
- **All system pods**: Running (etcd, kube-apiserver, kube-controller-manager, kube-scheduler, CoreDNS, Calico)
- **Test pod**: Successfully executes "Cluster is working!"
- **API Server**: Accessible and functional
- **Networking**: Calico CNI working across all nodes

## What This Creates

- **1 Master Node** (control plane)
- **2 Worker Nodes** (compute)
- **Basic EC2 instances** with Ubuntu 22.04 LTS
- **Security Groups** with proper firewall rules for Kubernetes
- **Pre-installed Kubernetes packages** (kubelet, kubeadm, kubectl)

## Simple Architecture

```
┌─────────────────────────────────────────┐
│              AWS EC2 Instances          │
│                                         │
│  ┌─────────────┐  ┌─────────────┐      │
│  │   Master-1  │  │   Worker-1  │      │
│  │ (Control    │  │  (Compute   │      │
│  │  Plane)     │  │   Node)     │      │
│  └─────────────┘  └─────────────┘      │
│                                         │
│  ┌─────────────┐                       │
│  │   Worker-2  │                       │
│  │  (Compute   │                       │
│  │   Node)     │                       │
│  └─────────────┘                       │
└─────────────────────────────────────────┘
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Make** utility installed (for automation)
4. **Ansible** installed (for cluster setup)
5. **AWS Permissions** for EC2 operations

### Installation Instructions

**macOS:**
```bash
# Make is pre-installed
# Install Ansible
brew install ansible
```

**Ubuntu/Debian:**
```bash
# Install Make and Ansible
sudo apt update
sudo apt install make ansible
```

**CentOS/RHEL:**
```bash
# Install Make and Ansible
sudo yum install make ansible
# or for newer versions:
sudo dnf install make ansible
```

## Quick Start with Makefile

The easiest way to set up the entire cluster:

```bash
# Step 1: Complete infrastructure setup (keys + terraform + inventory)
make setup-infra

# Step 2: Edit cluster-setup/inventory/hosts.yml with actual IPs from terraform output
# Step 3: Complete cluster setup
make setup-cluster

# Step 4: Install addon components (optional)
make setup-addons    # Install storage, ingress, cert-manager, metrics
make setup-argocd    # Install ArgoCD with VProfile app

# Or step by step:
make keys                    # Generate SSH keys
make apply                   # Create infrastructure
make inventory              # Create inventory file
# Edit cluster-setup/inventory/hosts.yml with actual IPs
make all                    # Deploy Kubernetes cluster
make aws-lb-controller      # Install AWS Load Balancer Controller
make nginx-ingress          # Install NGINX Ingress
make ebs-csi                # Install EBS CSI Driver
make efs-csi                # Install EFS CSI Driver
make cert-manager           # Install Cert Manager
make cluster-issuer         # Create ClusterIssuer
make metrics-server         # Install Metrics Server
make argocd                 # Install ArgoCD
make argocd-ingress         # Create ArgoCD Ingress
make argocd-vprofile        # Create ArgoCD VProfile app
```

## Complete Setup Workflow

### 1. Infrastructure Setup
```bash
make setup-infra
```
**What this does:**
- Generates SSH key pair (`k8s-cluster-key`)
- Initializes Terraform
- Creates AWS infrastructure (3 EC2 instances)
- Creates Ansible inventory template (`hosts-template.yml`)

**Next step:** Edit `cluster-setup/inventory/hosts.yml` with actual IP addresses from `terraform output`

### 2. Cluster Setup
```bash
make setup-cluster
```
**What this does:**
- Runs all Ansible playbooks to deploy Kubernetes
- Verifies prerequisites
- Configures hostnames
- Initializes master node
- Installs CNI (Calico)
- Joins worker nodes
- Verifies cluster is working
- Sets up kubectl autocomplete and alias

### 3. Install Addon Components (Optional)
```bash
# Install all addons at once
make setup-addons

# Or install individually
make aws-lb-controller      # AWS Load Balancer Controller
make nginx-ingress          # NGINX Ingress Controller
make ebs-csi                # EBS CSI Driver
make efs-csi                # EFS CSI Driver
make cert-manager           # Cert Manager
make cluster-issuer         # Let's Encrypt ClusterIssuer
make metrics-server         # Metrics Server
```

### 4. Install ArgoCD (Optional)
```bash
make setup-argocd
```
**What this does:**
- Installs ArgoCD
- Creates ArgoCD Ingress with TLS
- Creates VProfile AppProject
- Creates VProfile Application with automated sync

### 5. Cluster Cleanup (when done)
```bash
make cleanup-cluster
```
**What this does:**
- Force deletes all Kubernetes resources
- Runs `kubeadm reset -f` on all nodes
- Uninstalls Kubernetes packages
- Removes repositories and GPG keys
- Cleans up directories and network settings
- Resets configuration files

### 6. Complete Cleanup
```bash
make clean
```
**What this does:**
- First runs `cleanup-cluster` (see above)
- Then removes local files (SSH keys, inventory, logs, terraform files)

**Follow with:**
```bash
make destroy  # Destroy AWS infrastructure
```

### Available Makefile Targets

```bash
# Core Infrastructure
make help                   # Show all available commands
make keys                   # Generate SSH key pair
make init                   # Initialize Terraform
make plan                   # Plan deployment
make apply                  # Create infrastructure
make destroy                # Destroy infrastructure
make inventory              # Create inventory file

# Cluster Setup
make ping                   # Test connectivity
make prereq                 # Run prerequisites
make hostnames              # Configure hostnames
make master                 # Initialize master
make cni                    # Install CNI
make workers                # Join workers
make verify                 # Verify cluster
make kubectl-setup          # Setup kubectl autocomplete
make all                    # Run all core playbooks

# Addon Components
make aws-lb-controller      # Install AWS Load Balancer Controller
make nginx-ingress          # Install NGINX Ingress Controller
make ebs-csi                # Install EBS CSI Driver
make efs-csi                # Install EFS CSI Driver
make cert-manager           # Install Cert Manager
make cluster-issuer         # Create Let's Encrypt ClusterIssuer
make metrics-server         # Install Metrics Server
make argocd                 # Install ArgoCD
make argocd-ingress         # Create ArgoCD Ingress
make argocd-vprofile        # Create ArgoCD VProfile app

# Grouped Setup
make setup-storage          # Install storage drivers (EBS + EFS)
make setup-ingress          # Install ingress components (AWS LB + NGINX)
make setup-cert-manager     # Install cert-manager and ClusterIssuer
make setup-addons           # Install all addons
make setup-argocd           # Install ArgoCD with ingress and VProfile

# Complete Setup
make setup-infra            # Complete infrastructure setup
make setup-cluster          # Complete cluster setup
make cleanup-cluster        # Clean up Kubernetes resources
make clean                  # Clean up files
make status                 # Check cluster status
```

## Configuration

### Variables (variables.tf)

- `aws_region`: AWS region (default: us-east-1)
- `cluster_name`: Cluster name (default: 3-nodes-k8s-cluster)
- `master_instance_type`: Master node instance type (default: t3.medium)
- `worker_instance_type`: Worker node instance type (default: t3.medium)
- `kubernetes_version`: Kubernetes version (default: 1.28.0)

### Customization

Edit `variables.tf` to customize:
- Instance types
- Kubernetes version
- Cluster name

## Post-Deployment - Setting Up Kubernetes with kubeadm

After Terraform completes, you'll have 3 EC2 instances ready for Kubernetes setup:

1. **SSH to master node:**
   ```bash
   ssh -i k8s-cluster-key ubuntu@<master-public-ip>
   ```

2. **Initialize Kubernetes cluster:**
   ```bash
   sudo kubeadm init --pod-network-cidr=192.168.0.0/16
   ```

3. **Configure kubectl:**
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

4. **Install CNI (Calico):**
   ```bash
   kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
   ```

5. **Get join command for worker nodes:**
   ```bash
   sudo kubeadm token create --print-join-command
   ```

6. **SSH to worker nodes and join cluster:**
   ```bash
   ssh -i k8s-cluster-key ubuntu@<worker-public-ip>
   sudo <join-command-from-step-5>
   ```

7. **Verify cluster:**
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

## Automated Setup with Ansible

For automated cluster setup, you can use the provided Ansible playbooks:

### Prerequisites
1. **Install Ansible:**
   ```bash
   pip install ansible
   ```

2. **Update inventory file:**
   ```bash
   cp cluster-setup/inventory/hosts-template.yml cluster-setup/inventory/hosts.yml
   # Edit hosts.yml with your actual IP addresses from terraform output
   ```

3. **Test connectivity:**
   ```bash
   ansible all -m ping
   ```

### Run Individual Playbooks

1. **Verify prerequisites:**
   ```bash
   ansible-playbook cluster-setup/playbooks/01-verify-prerequisites.yml
   ```

2. **Configure hostnames:**
   ```bash
   ansible-playbook cluster-setup/playbooks/02-configure-hostnames.yml
   ```

3. **Initialize master node:**
   ```bash
   ansible-playbook cluster-setup/playbooks/03-initi-master.yml
   ```

4. **Install CNI (Calico):**
   ```bash
   ansible-playbook cluster-setup/playbooks/04-install-cni.yml
   ```

5. **Join worker nodes:**
   ```bash
   ansible-playbook cluster-setup/playbooks/05-join-workers.yml
   ```

6. **Verify cluster:**
   ```bash
   ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml
   ```

7. **Setup kubectl autocomplete and alias 'k':**
   ```bash
   ansible-playbook cluster-setup/playbooks/07-setup-kubectl-autocomplete.yml
   ```

### Run Playbooks with Verbose Output
```bash
ansible-playbook cluster-setup/playbooks/01-verify-Prerequisites.yml -v
```

### What Each Playbook Does

**07-setup-kubectl-autocomplete.yml:**
- Sets up kubectl bash completion for tab autocomplete
- Creates alias `k` for `kubectl` command
- Adds completion support for the `k` alias
- Configures `.bashrc` for persistent settings
- **Runs on:** Master nodes only
- **Benefit:** Faster kubectl commands with `k get pods` instead of `kubectl get pods`

### Expected Cluster Status After Setup
After running all playbooks, you should see:
- **3 nodes**: master1 (Ready), worker1 (Ready), worker2 (Ready)
- **All system pods**: Running (etcd, kube-apiserver, kube-controller-manager, kube-scheduler, CoreDNS, Calico)
- **Test pod**: Successfully executes "Cluster is working!"
- **API Server**: Accessible at `https://<master-ip>:6443`

### Troubleshooting Ansible
- **Check inventory:** `ansible all -m ping`
- **Test specific group:** `ansible masters -m ping`
- **View logs:** Check `ansible.log` file

## Security Groups

- **Masters**: SSH (22), Kubernetes API (6443), etcd (2379-2380), kubelet (10250), scheduler/controller-manager (10257, 10259)
- **Workers**: SSH (22), kubelet (10250), NodePort (30000-32767)
- **Load Balancer**: HTTP (80), HTTPS (443), Kubernetes API (6443)

This setup is perfect for practicing:

- **kubeadm cluster initialization**
- **Node management and troubleshooting**
- **Pod networking and CNI configuration**
- **Security contexts and RBAC**
- **Service and ingress configuration**
- **Persistent volumes and storage**
- **Cluster maintenance and upgrades**

## Cleanup Workflow

### Complete Cleanup (Recommended)

To properly clean up everything:

```bash
# 1. Clean up Kubernetes resources from VMs + local files
make clean

# 2. Destroy AWS infrastructure
make destroy
```

### Individual Cleanup Steps

```bash
# Clean up Kubernetes resources from VMs only (fast - keeps infrastructure)
make cleanup-cluster

# Clean up local files only (SSH keys, inventory, logs, terraform files - keeps infrastructure)
make clean

# Destroy AWS infrastructure (deletes everything)
make destroy
```

### What Each Cleanup Command Does:

**`make cleanup-cluster` (Fast - 30 seconds):**
1. Runs `kubeadm reset -f` on all nodes
2. Quickly resets cluster state
3. **Keeps infrastructure running** - only resets Kubernetes
4. Perfect for testing cycles and quick resets

**`make clean`:**
1. First runs `cleanup-cluster` (see above)
2. Then removes local files (SSH keys, inventory, logs)
3. **Keeps terraform files** - so you can still run `make destroy`
4. **Keeps infrastructure running** - only cleans up local files

**`make destroy`:**
1. **Destroys all AWS infrastructure** (EC2 instances, security groups, key pairs)
2. **Cleans up terraform files** (.terraform/, terraform.tfstate*)
3. **Only command that actually deletes infrastructure**

## Troubleshooting

1. **Check Kubernetes status:**
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

2. **Reset kubeadm (if needed):**
   ```bash
   sudo kubeadm reset
   ```

3. **Check cluster connectivity:**
   ```bash
   ansible all -m ping
   ```


