region = "us-east-1"
env = "dev"

# Cluster Name (used for all infrastructure)
cluster_name = "3-nodes-k8s-cluster"

# Availability Zones (used for all infrastructure)
az1 = "us-east-1a"
az2 = "us-east-1b"

# ==============================================================================
# Terraform State Backend Configuration
# ==============================================================================
terraform_state_bucket = "vprofile-move356234-add-terraform-state"
bucket = "vprofile-move356234-add-terraform-state"

# ==============================================================================
# VPC Configuration
# ==============================================================================
vpc_cidr = "10.0.0.0/16"
private_subnet1_cidr = "10.0.1.0/24"
private_subnet2_cidr = "10.0.2.0/24"
public_subnet1_cidr = "10.0.11.0/24"
public_subnet2_cidr = "10.0.12.0/24"
terraform_s3_bucket = "vprofile-move356234-add-terraform-state"

# ==============================================================================
# Instance Configuration
# ==============================================================================
master_instance_type = "t3.medium"
worker_instance_type = "t3.medium"
key_pair_name = "3-nodes-k8s-keypair"

# ==============================================================================
# IAM Role Names (optional - defaults to environment-cluster_name-{service})
# ==============================================================================
aws_lbc_role_name = "dev-3-nodes-k8s-cluster-aws-lbc"
aws_lbc_policy_name = "dev-3-nodes-k8s-cluster-AWSLoadBalancerController"
ebs_csi_driver_role_name = "dev-3-nodes-k8s-cluster-ebs-csi-driver"
efs_csi_driver_role_name = "dev-3-nodes-k8s-cluster-efs-csi-driver"

# ==============================================================================
# IAM Role Tag Names (optional - defaults to cluster_name-{service}-role)
# ==============================================================================
aws_lbc_role_tag_name = "3-nodes-k8s-cluster-aws-lbc-role"
aws_lbc_role_tag_description = "IAM role for AWS Load Balancer Controller"
aws_lbc_policy_tag_name = "3-nodes-k8s-cluster-aws-lbc-policy"
ebs_csi_driver_role_tag_name = "3-nodes-k8s-cluster-ebs-csi-driver-role"
ebs_csi_driver_role_tag_description = "IAM role for EBS CSI Driver"
efs_csi_driver_role_tag_name = "3-nodes-k8s-cluster-efs-csi-driver-role"
efs_csi_driver_role_tag_description = "IAM role for EFS CSI Driver"

# ==============================================================================
# EFS Configuration (optional)
# ==============================================================================
efs_creation_token = "k8s-efs"
efs_file_system_name = "3-nodes-k8s-cluster-efs"
efs_performance_mode = "generalPurpose"
efs_throughput_mode = "bursting"
efs_encrypted = true

# ==============================================================================
# Cert Manager Configuration
# ==============================================================================
cert_manager_email = "admin@example.com"

# ==============================================================================
# ArgoCD Configuration
# ==============================================================================
argocd_domain = "argocd.example.com"
argocd_cert_issuer = "http-01-production"
argocd_cert_secret_name = "argocd-tls"
argocd_project_name = "vprofile"
argocd_app_name = "vprofile"
argocd_app_destination_namespace = "vprofile"
argocd_app_source_path = "k8s"
argocd_app_repo_url = "https://github.com/example/vprofile-app.git"
argocd_app_repo_target_revision = "main"
