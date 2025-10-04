# Makefile for 3-Node Kubernetes Cluster Setup
# This Makefile automates the entire process from key generation to cluster deployment

.PHONY: help keys init plan apply destroy inventory ping prereq hostnames master cni workers verify all clean setup-infra setup-cluster cleanup-cluster

# Default target
help:
	@echo "3-Node Kubernetes Cluster Setup"
	@echo "================================"
	@echo ""
	@echo "Available targets:"
	@echo "  help          - Show this help message"
	@echo "  keys          - Generate SSH key pair"
	@echo "  init          - Initialize Terraform"
	@echo "  plan          - Plan Terraform deployment"
	@echo "  apply         - Apply Terraform configuration"
	@echo "  destroy       - Destroy all infrastructure"
	@echo "  inventory     - Create inventory file from Terraform output"
	@echo "  ping          - Test connectivity to all nodes"
	@echo "  prereq        - Run prerequisites playbook"
	@echo "  hostnames     - Configure hostnames"
	@echo "  master        - Initialize master node"
	@echo "  cni           - Install CNI (Calico)"
	@echo "  workers       - Join worker nodes"
	@echo "  verify        - Verify cluster"
	@echo "  all           - Run all Ansible playbooks"
	@echo "  setup-infra   - Complete infrastructure setup (keys + terraform + inventory)"
	@echo "  setup-cluster - Complete cluster setup (requires updated hosts.yml)"
	@echo "  cleanup-cluster - Clean up Kubernetes resources from VMs"
	@echo "  clean         - Clean up generated files"
	@echo ""
	@echo "Quick start:"
	@echo "  make setup-infra   - Setup infrastructure first"
	@echo "  make setup-cluster - Setup cluster (after editing hosts.yml)"
	@echo "  make clean         - Clean up and start over"

# Generate SSH key pair
keys:
	@echo "Generating SSH key pair..."
	@./scripts/generate-keys.sh

# Terraform commands
init:
	@echo "Initializing Terraform..."
	@terraform init

plan: init
	@echo "Planning Terraform deployment..."
	@terraform plan

apply: init
	@echo "Applying Terraform configuration..."
	@terraform apply -auto-approve

destroy:
	@echo "Destroying infrastructure..."
	@terraform destroy -auto-approve

# Create inventory file from Terraform output
inventory:
	@echo "Creating inventory file from Terraform output..."
	@cp cluster-setup/inventory/hosts-template.yml cluster-setup/inventory/hosts.yml
	@echo "Please update cluster-setup/inventory/hosts.yml with actual IP addresses from:"
	@echo "terraform output"

# Ansible commands
ping:
	@echo "Testing connectivity to all nodes..."
	@ansible all -m ping

prereq:
	@echo "Running prerequisites playbook..."
	@ansible-playbook cluster-setup/playbooks/01-verify-prerequisites.yml

hostnames:
	@echo "Configuring hostnames..."
	@ansible-playbook cluster-setup/playbooks/02-configure-hostnames.yml

master:
	@echo "Initializing master node..."
	@ansible-playbook cluster-setup/playbooks/03-initi-master.yml

cni:
	@echo "Installing CNI (Calico)..."
	@ansible-playbook cluster-setup/playbooks/04-install-cni.yml

workers:
	@echo "Joining worker nodes..."
	@ansible-playbook cluster-setup/playbooks/05-join-workers.yml

verify:
	@echo "Verifying cluster..."
	@ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml

all:
	@echo "Running all Ansible playbooks..."
	@ansible-playbook cluster-setup/playbooks/01-verify-prerequisites.yml
	@ansible-playbook cluster-setup/playbooks/02-configure-hostnames.yml
	@ansible-playbook cluster-setup/playbooks/03-initi-master.yml
	@ansible-playbook cluster-setup/playbooks/04-install-cni.yml
	@ansible-playbook cluster-setup/playbooks/05-join-workers.yml
	@ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml

# Complete setup process
setup-infra: keys apply inventory
	@echo ""
	@echo "🎉 Infrastructure setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Edit cluster-setup/inventory/hosts.yml with actual IP addresses from:"
	@echo "   terraform output"
	@echo "2. Run: make setup-cluster"
	@echo ""

setup-cluster: all
	@echo ""
	@echo "🎉 Kubernetes cluster setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. SSH to master: ssh -i k8s-cluster-key ubuntu@\$$(terraform output -raw master_public_ips)"
	@echo "2. Check cluster: kubectl get nodes"
	@echo "3. View pods: kubectl get pods -A"
	@echo ""
	@echo "To destroy: make destroy"

# Clean up Kubernetes resources from VMs
cleanup-cluster:
	@echo "Cleaning up Kubernetes resources from VMs..."
	@ansible-playbook cluster-setup/playbooks/07-cleanup-cluster.yml
	@echo ""
	@echo "Kubernetes cleanup completed!"
	@echo "You can now safely run: make destroy"

# Clean up generated files
clean: cleanup-cluster
	@echo "Cleaning up generated files..."
	@rm -f k8s-cluster-key k8s-cluster-key.pub
	@rm -f cluster-setup/inventory/hosts.yml
	@rm -f ansible.log
	@rm -rf .terraform
	@rm -f terraform.tfstate*
	@echo "Cleanup complete!"

# Development helpers
dev-setup: keys init
	@echo "Development setup complete. Run 'make apply' to create infrastructure."

dev-ansible: inventory all
	@echo "Ansible setup complete. Cluster should be ready!"

# Status check
status:
	@echo "Checking cluster status..."
	@ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml
