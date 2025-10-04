# 3-Node Kubernetes Infrastructure Setup on AWS

This Terraform configuration creates a simple 3-node infrastructure on AWS for setting up a Kubernetes cluster with kubeadm, perfect for learning the internals of kubernetes.

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

## Quick Start

1. **Generate SSH key pair:**
   ```bash
   ./scripts/generate-keys.sh
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

5. **Get instance information:**
   ```bash
   terraform output
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


