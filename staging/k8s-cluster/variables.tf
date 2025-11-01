variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "3-nodes-k8s-cluster"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "master_instance_type" {
  description = "EC2 instance type for master nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = "3-nodes-k8s-keypair"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.0"
}

variable "cert_manager_email" {
  description = "Email address for Let's Encrypt certificate requests"
  type        = string
  default     = "admin@example.com"
}

variable "argocd_domain" {
  description = "Domain name for ArgoCD ingress"
  type        = string
  default     = "argocd.example.com"
}

variable "argocd_cert_issuer" {
  description = "Cert-manager ClusterIssuer name for ArgoCD"
  type        = string
  default     = "http-01-production"
}

variable "argocd_cert_secret_name" {
  description = "Secret name for ArgoCD TLS certificate"
  type        = string
  default     = "argocd-tls"
}

variable "argocd_project_name" {
  description = "Name of the ArgoCD AppProject"
  type        = string
  default     = "vprofile"
}

variable "argocd_app_name" {
  description = "Name of the ArgoCD Application"
  type        = string
  default     = "vprofile"
}

variable "argocd_app_destination_namespace" {
  description = "Destination namespace for ArgoCD application"
  type        = string
  default     = "vprofile"
}

variable "argocd_app_source_path" {
  description = "Source path in the Git repository for ArgoCD application"
  type        = string
  default     = "k8s"
}

variable "argocd_app_repo_url" {
  description = "Git repository URL for ArgoCD application"
  type        = string
  default     = "https://github.com/example/vprofile-app.git"
}

variable "argocd_app_repo_target_revision" {
  description = "Git branch/tag/commit for ArgoCD application"
  type        = string
  default     = "main"
}

# IAM Role Names
variable "aws_lbc_role_name" {
  description = "Name of the IAM role for AWS Load Balancer Controller"
  type        = string
  default     = ""
}

variable "aws_lbc_policy_name" {
  description = "Name of the IAM policy for AWS Load Balancer Controller"
  type        = string
  default     = ""
}

variable "ebs_csi_driver_role_name" {
  description = "Name of the IAM role for EBS CSI Driver"
  type        = string
  default     = ""
}

variable "efs_csi_driver_role_name" {
  description = "Name of the IAM role for EFS CSI Driver"
  type        = string
  default     = ""
}

# IAM Role Tags
variable "aws_lbc_role_tag_name" {
  description = "Tag Name for AWS Load Balancer Controller IAM role"
  type        = string
  default     = ""
}

variable "aws_lbc_role_tag_description" {
  description = "Tag Description for AWS Load Balancer Controller IAM role"
  type        = string
  default     = "IAM role for AWS Load Balancer Controller"
}

variable "aws_lbc_policy_tag_name" {
  description = "Tag Name for AWS Load Balancer Controller IAM policy"
  type        = string
  default     = ""
}

variable "ebs_csi_driver_role_tag_name" {
  description = "Tag Name for EBS CSI Driver IAM role"
  type        = string
  default     = ""
}

variable "ebs_csi_driver_role_tag_description" {
  description = "Tag Description for EBS CSI Driver IAM role"
  type        = string
  default     = "IAM role for EBS CSI Driver"
}

variable "efs_csi_driver_role_tag_name" {
  description = "Tag Name for EFS CSI Driver IAM role"
  type        = string
  default     = ""
}

variable "efs_csi_driver_role_tag_description" {
  description = "Tag Description for EFS CSI Driver IAM role"
  type        = string
  default     = "IAM role for EFS CSI Driver"
}

# EFS Configuration
variable "efs_creation_token" {
  description = "Creation token for EFS file system"
  type        = string
  default     = "k8s-efs"
}

variable "efs_file_system_name" {
  description = "Name tag for EFS file system"
  type        = string
  default     = ""
}

variable "efs_performance_mode" {
  description = "Performance mode for EFS file system"
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "Throughput mode for EFS file system"
  type        = string
  default     = "bursting"
}

variable "efs_encrypted" {
  description = "Whether EFS file system should be encrypted"
  type        = bool
  default     = true
}

variable "terraform_s3_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

# etcd Backup Configuration
variable "etcd_backup_retention_days" {
  description = "Number of days to retain etcd backups"
  type        = number
  default     = 90
}

variable "etcd_backup_role_name" {
  description = "Name of the IAM role for etcd backup"
  type        = string
  default     = ""
}

variable "etcd_backup_policy_name" {
  description = "Name of the IAM policy for etcd backup"
  type        = string
  default     = ""
}

variable "etcd_backup_instance_profile_name" {
  description = "Name of the IAM instance profile for etcd backup"
  type        = string
  default     = ""
}

variable "etcd_backup_role_tag_name" {
  description = "Tag Name for etcd backup IAM role"
  type        = string
  default     = ""
}

variable "etcd_backup_role_tag_description" {
  description = "Tag Description for etcd backup IAM role"
  type        = string
  default     = "IAM role for etcd backup to S3"
}

variable "etcd_backup_policy_tag_name" {
  description = "Tag Name for etcd backup IAM policy"
  type        = string
  default     = ""
}
