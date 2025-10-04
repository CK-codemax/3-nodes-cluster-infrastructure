# 3-Node Kubernetes Infrastructure Setup on AWS

This Terraform configuration creates a simple 3-node infrastructure on AWS for setting up a Kubernetes cluster with kubeadm, perfect for learning the internals of kubernetes.

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
3. **AWS Permissions** for EC2 operations

## Quick Start with Makefile

The easiest way to set up the entire cluster:

```bash
# Complete setup (keys + infrastructure + cluster)
make setup

# Or step by step:
make keys                    # Generate SSH keys
make apply                   # Create infrastructure
make inventory              # Create inventory file
# Edit cluster-setup/inventory/hosts.yml with actual IPs
make all                    # Deploy Kubernetes cluster
```

### Available Makefile Targets

```bash
make help                   # Show all available commands
make keys                   # Generate SSH key pair
make init                   # Initialize Terraform
make plan                   # Plan deployment
make apply                  # Create infrastructure
make destroy                # Destroy infrastructure
make inventory              # Create inventory file
make ping                   # Test connectivity
make prereq                 # Run prerequisites
make hostnames              # Configure hostnames
make master                 # Initialize master
make cni                    # Install CNI
make workers                # Join workers
make verify                 # Verify cluster
make all                    # Run all playbooks
make setup                  # Complete setup
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

### Run All Playbooks
```bash
ansible-playbook cluster-setup/playbooks/*.yml
```

### Run All Playbooks with Verbose Output
```bash
ansible-playbook cluster-setup/playbooks/*.yml -v
```

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

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

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

3. **Re-run all playbooks (clean setup):**
   ```bash
   ansible-playbook cluster-setup/playbooks/*.yml
   ```

4. **Check cluster connectivity:**
   ```bash
   ansible all -m ping
   ```

5. **View Ansible logs:**
   ```bash
   tail -f ansible.log
   ```


