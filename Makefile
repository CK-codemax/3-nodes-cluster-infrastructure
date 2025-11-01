# ==============================================================================
# 3-Node Kubernetes Cluster Infrastructure Makefile
# ==============================================================================

.PHONY: help keys init-s3 deploy-s3 migrate-s3-backend deploy-vpc deploy-k8s-cluster deploy-infrastructure
.PHONY: deploy-all destroy-all destroy-k8s-cluster destroy-vpc destroy-infrastructure
.PHONY: plan-s3 plan-vpc plan-k8s-cluster plan-all
.PHONY: inventory ping prereq hostnames master cni workers verify kubectl-setup all
.PHONY: aws-lb-controller nginx-ingress ebs-csi efs-csi cert-manager cluster-issuer metrics-server
.PHONY: argocd argocd-ingress argocd-vprofile
.PHONY: cleanup-cluster clean status verify-cluster

# Variables
TFVARS := terraform.tfvars
STATE_CONFIG := state.config
S3_DIR := global/s3-state
VPC_DIR := staging/vpc
K8S_CLUSTER_DIR := staging/k8s-cluster
TFVARS_PATH := $(abspath $(TFVARS))
STATE_CONFIG_PATH := $(abspath $(STATE_CONFIG))

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# ==============================================================================
# Help Target
# ==============================================================================
.DEFAULT_GOAL := help

help:
	@echo "$(GREEN)3-Node Kubernetes Cluster Infrastructure Deployment$(NC)"
	@echo ""
	@echo "$(YELLOW)Infrastructure Targets:$(NC)"
	@echo "  make init-s3              - Initialize S3 backend (first time only)"
	@echo "  make deploy-s3             - Deploy S3 backend"
	@echo "  make migrate-s3-backend    - Migrate S3 backend state to S3"
	@echo "  make deploy-vpc            - Deploy VPC infrastructure"
	@echo "  make deploy-k8s-cluster    - Deploy Kubernetes cluster infrastructure"
	@echo "  make deploy-infrastructure - Deploy VPC and K8s cluster sequentially"
	@echo ""
	@echo "$(YELLOW)Planning Targets:$(NC)"
	@echo "  make plan-s3          - Plan S3 backend changes"
	@echo "  make plan-vpc         - Plan VPC changes"
	@echo "  make plan-k8s-cluster - Plan K8s cluster changes"
	@echo "  make plan-all         - Plan all infrastructure changes"
	@echo ""
	@echo "$(YELLOW)Cluster Setup Targets (Ansible):$(NC)"
	@echo "  make keys          - Generate SSH key pair"
	@echo "  make inventory     - Create inventory file from Terraform output"
	@echo "  make ping          - Test connectivity to all nodes"
	@echo "  make prereq        - Run prerequisites playbook"
	@echo "  make hostnames     - Configure hostnames"
	@echo "  make master        - Initialize master node"
	@echo "  make cni           - Install CNI (Calico)"
	@echo "  make workers       - Join worker nodes"
	@echo "  make verify        - Verify cluster"
	@echo "  make kubectl-setup - Setup kubectl autocomplete and alias 'k'"
	@echo "  make all           - Run all core Ansible playbooks"
	@echo ""
	@echo "$(YELLOW)Addon Components (Ansible):$(NC)"
	@echo "  make aws-lb-controller - Install AWS Load Balancer Controller"
	@echo "  make nginx-ingress     - Install NGINX Ingress Controller"
	@echo "  make ebs-csi           - Install EBS CSI Driver"
	@echo "  make efs-csi           - Install EFS CSI Driver"
	@echo "  make cert-manager      - Install Cert Manager"
	@echo "  make cluster-issuer    - Create Let's Encrypt ClusterIssuer"
	@echo "  make metrics-server    - Install Metrics Server"
	@echo "  make argocd            - Install ArgoCD"
	@echo "  make argocd-ingress    - Create ArgoCD Ingress"
	@echo "  make argocd-vprofile   - Create ArgoCD VProfile Project and App"
	@echo ""
	@echo "$(YELLOW)Complete Setup:$(NC)"
	@echo "  make deploy-all         - Deploy infrastructure + setup cluster + addons"
	@echo "  make setup-infra        - Complete infrastructure setup (keys + terraform + inventory)"
	@echo "  make setup-cluster      - Complete cluster setup (requires updated hosts.yml)"
	@echo ""
	@echo "$(YELLOW)Destruction Targets:$(NC)"
	@echo "  make destroy-k8s-cluster  - Destroy K8s cluster infrastructure"
	@echo "  make destroy-vpc          - Destroy VPC infrastructure"
	@echo "  make destroy-infrastructure - Destroy VPC and K8s cluster"
	@echo "  make cleanup-cluster      - Clean up Kubernetes resources from VMs (fast)"
	@echo "  make clean                - Clean Terraform plan files and generated files"
	@echo ""
	@echo "$(YELLOW)Utility Targets:$(NC)"
	@echo "  make verify-cluster  - Verify cluster access"
	@echo "  make status          - Check cluster status"
	@echo ""
	@echo "$(YELLOW)Quick start:$(NC)"
	@echo "  make deploy-all       - Complete deployment (infrastructure + cluster + addons)"
	@echo "  make setup-infra      - Setup infrastructure first"
	@echo "  make setup-cluster    - Setup cluster (after editing hosts.yml)"

# ==============================================================================
# S3 Backend Setup
# ==============================================================================
init-s3:
	@echo "$(GREEN)Initializing S3 backend...$(NC)"
	@cd $(S3_DIR) && terraform init -input=false -backend-config=../../$(STATE_CONFIG)

deploy-s3:
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)Deploying S3 backend...$(NC)"
	@cd $(S3_DIR) && \
		terraform init -input=false && \
		terraform plan -input=false -compact-warnings -var-file=$(TFVARS_PATH) -out=tfplan && \
		terraform apply -input=false -auto-approve tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ S3 backend deployed$(NC)"
	@echo ""
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)IMPORTANT: Before migrating to S3 backend:$(NC)"
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)1. Uncomment the backend configuration in:$(NC)"
	@echo "   $(S3_DIR)/state.tf"
	@echo ""
	@echo "$(BLUE)2. Then run:$(NC)"
	@echo "   make migrate-s3-backend"
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

migrate-s3-backend:
	@echo "$(GREEN)Migrating S3 backend state...$(NC)"
	@cd $(S3_DIR) && echo "yes" | terraform init -migrate-state -backend-config=../../$(STATE_CONFIG)
	@echo "$(GREEN)✓ S3 backend state migrated$(NC)"

plan-s3:
	@echo "$(YELLOW)Planning S3 backend changes...$(NC)"
	@cd $(S3_DIR) && \
		terraform init -input=false && \
		terraform plan -input=false -compact-warnings -var-file=$(TFVARS_PATH)

# ==============================================================================
# Infrastructure Deployment
# ==============================================================================
deploy-vpc:
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)Deploying VPC...$(NC)"
	@cd $(VPC_DIR) && \
		terraform init -input=false -backend-config=../../$(STATE_CONFIG) -backend-config="key=staging/vpc/terraform.tfstate" && \
		terraform plan -input=false -compact-warnings -var-file=$(TFVARS_PATH) -out=tfplan && \
		terraform apply -input=false -auto-approve tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ VPC deployed successfully$(NC)"

deploy-k8s-cluster:
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)Deploying Kubernetes cluster infrastructure...$(NC)"
	@cd $(K8S_CLUSTER_DIR) && \
		terraform init -input=false -backend-config=../../$(STATE_CONFIG) -backend-config="key=staging/k8s-cluster/terraform.tfstate" && \
		terraform plan -input=false -compact-warnings -var-file=$(TFVARS_PATH) -out=tfplan && \
		terraform apply -input=false -auto-approve tfplan && \
		rm -f tfplan
	@echo "$(GREEN)✓ Kubernetes cluster infrastructure deployed successfully$(NC)"
	@echo ""
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)IMPORTANT: Update Ansible variables$(NC)"
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(BLUE)Ansible playbooks will automatically fetch Terraform outputs at runtime.$(NC)"
	@echo "$(BLUE)However, you can manually update cluster-setup/vars/main.yml if needed.$(NC)"
	@echo ""
	@echo "$(BLUE)To view all Terraform outputs:$(NC)"
	@echo "  cd $(K8S_CLUSTER_DIR) && terraform output"
	@echo "$(YELLOW)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"

deploy-infrastructure: deploy-vpc deploy-k8s-cluster
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)Infrastructure deployment completed!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Create inventory: make inventory"
	@echo "  2. Edit cluster-setup/inventory/hosts.yml with actual IP addresses"
	@echo "  3. Setup cluster: make setup-cluster"
	@echo "  4. Deploy addons: make setup-addons"

plan-vpc:
	@echo "$(YELLOW)Planning VPC changes...$(NC)"
	@cd $(VPC_DIR) && \
		terraform init -input=false -backend-config=../../$(STATE_CONFIG) -backend-config="key=staging/vpc/terraform.tfstate" && \
		terraform plan -input=false -compact-warnings -var-file=$(TFVARS_PATH)

plan-k8s-cluster:
	@echo "$(YELLOW)Planning K8s cluster changes...$(NC)"
	@cd $(K8S_CLUSTER_DIR) && \
		terraform init -input=false -backend-config=../../$(STATE_CONFIG) -backend-config="key=staging/k8s-cluster/terraform.tfstate" && \
		terraform plan -input=false -compact-warnings -var-file=$(TFVARS_PATH)

plan-all: plan-s3 plan-vpc plan-k8s-cluster
	@echo "$(GREEN)All infrastructure planning completed$(NC)"

# ==============================================================================
# Destruction Targets
# ==============================================================================
destroy-k8s-cluster:
	@echo "$(RED)Destroying Kubernetes cluster infrastructure...$(NC)"
	@cd $(K8S_CLUSTER_DIR) && \
		terraform init -input=false -backend-config=../../$(STATE_CONFIG) -backend-config="key=staging/k8s-cluster/terraform.tfstate" && \
		terraform destroy -input=false -compact-warnings -var-file=$(TFVARS_PATH) -auto-approve
	@echo "$(GREEN)✓ Kubernetes cluster infrastructure destroyed$(NC)"

destroy-vpc:
	@echo "$(RED)Destroying VPC infrastructure...$(NC)"
	@cd $(VPC_DIR) && \
		terraform init -input=false -backend-config=../../$(STATE_CONFIG) -backend-config="key=staging/vpc/terraform.tfstate" && \
		terraform destroy -input=false -compact-warnings -var-file=$(TFVARS_PATH) -auto-approve
	@echo "$(GREEN)✓ VPC infrastructure destroyed$(NC)"

destroy-infrastructure: destroy-k8s-cluster destroy-vpc
	@echo "$(GREEN)Infrastructure destroyed$(NC)"

destroy-all: cleanup-cluster destroy-infrastructure
	@echo "$(GREEN)All resources destroyed$(NC)"

# ==============================================================================
# SSH Keys and Inventory
# ==============================================================================
keys:
	@echo "$(GREEN)Generating SSH key pair...$(NC)"
	@./scripts/generate-keys.sh
	@echo "$(GREEN)✓ SSH keys generated$(NC)"

inventory:
	@echo "$(GREEN)Creating inventory file from Terraform output...$(NC)"
	@if [ ! -d cluster-setup/inventory ]; then \
		mkdir -p cluster-setup/inventory; \
	fi
	@if [ -f cluster-setup/inventory/hosts-template.yml ]; then \
		cp cluster-setup/inventory/hosts-template.yml cluster-setup/inventory/hosts.yml; \
	else \
		echo "$(YELLOW)Warning: hosts-template.yml not found. Creating basic template.$(NC)"; \
		cat > cluster-setup/inventory/hosts.yml << 'EOF'; \
all: \
  children: \
    masters: \
      hosts: \
        master1: \
          ansible_host: PLACEHOLDER_MASTER_IP \
    workers: \
      hosts: \
        worker1: \
          ansible_host: PLACEHOLDER_WORKER1_IP \
        worker2: \
          ansible_host: PLACEHOLDER_WORKER2_IP \
EOF \
	fi
	@echo "$(YELLOW)Please update cluster-setup/inventory/hosts.yml with actual IP addresses from:$(NC)"
	@echo "$(BLUE)cd $(K8S_CLUSTER_DIR) && terraform output$(NC)"

# ==============================================================================
# Ansible Commands
# ==============================================================================
ping:
	@echo "$(GREEN)Testing connectivity to all nodes...$(NC)"
	@ansible all -m ping

prereq:
	@echo "$(GREEN)Running prerequisites playbook...$(NC)"
	@ansible-playbook cluster-setup/playbooks/01-verify-prerequisites.yml

hostnames:
	@echo "$(GREEN)Configuring hostnames...$(NC)"
	@ansible-playbook cluster-setup/playbooks/02-configure-hostnames.yml

master:
	@echo "$(GREEN)Initializing master node...$(NC)"
	@ansible-playbook cluster-setup/playbooks/03-initi-master.yml

cni:
	@echo "$(GREEN)Installing CNI (Calico)...$(NC)"
	@ansible-playbook cluster-setup/playbooks/04-install-cni.yml

workers:
	@echo "$(GREEN)Joining worker nodes...$(NC)"
	@ansible-playbook cluster-setup/playbooks/05-join-workers.yml

verify:
	@echo "$(GREEN)Verifying cluster...$(NC)"
	@ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml

kubectl-setup:
	@echo "$(GREEN)Setting up kubectl autocomplete and alias 'k'...$(NC)"
	@ansible-playbook cluster-setup/playbooks/07-setup-kubectl-autocomplete.yml

# ==============================================================================
# Addon Component Targets
# ==============================================================================
aws-lb-controller:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Installing AWS Load Balancer Controller...$(NC)"
	@ansible-playbook cluster-setup/playbooks/09-install-aws-lb-controller.yml
	@echo "$(GREEN)✓ AWS Load Balancer Controller installed$(NC)"

nginx-ingress:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Installing NGINX Ingress Controller...$(NC)"
	@ansible-playbook cluster-setup/playbooks/10-install-nginx-ingress.yml
	@echo "$(GREEN)✓ NGINX Ingress Controller installed$(NC)"

ebs-csi:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Installing EBS CSI Driver...$(NC)"
	@ansible-playbook cluster-setup/playbooks/11-install-ebs-csi-driver.yml
	@echo "$(GREEN)✓ EBS CSI Driver installed$(NC)"

efs-csi:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Installing EFS CSI Driver...$(NC)"
	@ansible-playbook cluster-setup/playbooks/12-install-efs-csi-driver.yml
	@echo "$(GREEN)✓ EFS CSI Driver installed$(NC)"

cert-manager:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Installing Cert Manager...$(NC)"
	@ansible-playbook cluster-setup/playbooks/13-install-cert-manager.yml
	@echo "$(GREEN)✓ Cert Manager installed$(NC)"

cluster-issuer:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Creating Let's Encrypt ClusterIssuer...$(NC)"
	@ansible-playbook cluster-setup/playbooks/14-create-cluster-issuer.yml
	@echo "$(GREEN)✓ ClusterIssuer created$(NC)"

metrics-server:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Installing Metrics Server...$(NC)"
	@ansible-playbook cluster-setup/playbooks/15-install-metrics-server.yml
	@echo "$(GREEN)✓ Metrics Server installed$(NC)"

argocd:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Installing ArgoCD...$(NC)"
	@ansible-playbook cluster-setup/playbooks/16-install-argocd.yml
	@echo "$(GREEN)✓ ArgoCD installed$(NC)"

argocd-ingress:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Creating ArgoCD Ingress...$(NC)"
	@ansible-playbook cluster-setup/playbooks/17-create-argocd-ingress.yml
	@echo "$(GREEN)✓ ArgoCD Ingress created$(NC)"

argocd-vprofile:
	@echo "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(YELLOW)Creating ArgoCD VProfile Project and Application...$(NC)"
	@ansible-playbook cluster-setup/playbooks/18-create-argocd-vprofile.yml
	@echo "$(GREEN)✓ ArgoCD VProfile app created$(NC)"

all: ping prereq hostnames master cni workers verify kubectl-setup aws-lb-controller nginx-ingress ebs-csi efs-csi cert-manager cluster-issuer metrics-server argocd argocd-ingress argocd-vprofile
	@echo "$(GREEN)✓ All playbooks completed$(NC)"

# ==============================================================================
# Complete Setup Process
# ==============================================================================
setup-infra: keys deploy-infrastructure inventory
	@echo ""
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)🎉 Infrastructure setup complete!$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Edit cluster-setup/inventory/hosts.yml with actual IP addresses from:"
	@echo "     cd $(K8S_CLUSTER_DIR) && terraform output"
	@echo "  2. Run: make setup-cluster"
	@echo ""

setup-cluster: all
	@echo ""
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)🎉 Kubernetes cluster setup complete!$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. SSH to master: ssh -i k8s-cluster-key ubuntu@\$$(cd $(K8S_CLUSTER_DIR) && terraform output -raw master_public_ips | head -n1)"
	@echo "  2. Check cluster: kubectl get nodes"
	@echo "  3. View pods: kubectl get pods -A"
	@echo ""
	@echo "To destroy: make destroy-infrastructure"

deploy-all: deploy-infrastructure inventory setup-cluster
	@echo ""
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo "$(GREEN)🎉 Complete deployment finished!$(NC)"
	@echo "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "Verification commands:"
	@echo "  kubectl get nodes"
	@echo "  kubectl get pods --all-namespaces"
	@echo "  kubectl get ingress -n argocd"
	@echo "  kubectl get application -n argocd"

# ==============================================================================
# Cleanup and Utility Targets
# ==============================================================================
cleanup-cluster:
	@echo "$(YELLOW)Cleaning up Kubernetes resources from VMs...$(NC)"
	@echo "Running kubeadm reset on all nodes..."
	@ansible all -m shell -a "kubeadm reset -f" --become || true
	@echo ""
	@echo "$(GREEN)Kubernetes cleanup completed!$(NC)"
	@echo "You can now safely run: make destroy-infrastructure"

clean:
	@echo "$(YELLOW)Cleaning Terraform plan files and generated files...$(NC)"
	@find . -name "tfplan" -type f -delete 2>/dev/null || true
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true
	@rm -f k8s-cluster-key k8s-cluster-key.pub
	@rm -f cluster-setup/inventory/hosts.yml
	@rm -f ansible.log
	@echo "$(GREEN)✓ Cleaned$(NC)"

verify-cluster:
	@echo "$(YELLOW)Verifying cluster access...$(NC)"
	@ansible all -m ping > /dev/null 2>&1 || (echo "$(RED)✗ Failed to connect to cluster$(NC)" && exit 1)
	@echo "$(GREEN)✓ Cluster access verified$(NC)"

status:
	@echo "$(YELLOW)Checking cluster status...$(NC)"
	@ansible-playbook cluster-setup/playbooks/06-verify-cluster.yml
