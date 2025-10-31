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

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
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
