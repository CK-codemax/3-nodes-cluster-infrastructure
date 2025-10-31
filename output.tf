output "ssh_commands" {
  description = "SSH commands to connect to each instance"
  value = {
    master_ssh = "ssh -i k8s-cluster-key ubuntu@${aws_instance.masters[0].public_ip}"
    worker1_ssh = "ssh -i k8s-cluster-key ubuntu@${aws_instance.workers[0].public_ip}"
    worker2_ssh = "ssh -i k8s-cluster-key ubuntu@${aws_instance.workers[1].public_ip}"
  }
}

output "master_public_ips" {
  description = "Public IP addresses of the master instances"
  value       = aws_instance.masters[*].public_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of the worker instances"
  value       = aws_instance.workers[*].public_ip
}

# Outputs for Ansible playbooks
output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = var.cluster_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.default.id
}

output "cert_manager_email" {
  description = "Email address for cert-manager"
  value       = var.cert_manager_email
}

output "argocd_domain" {
  description = "Domain name for ArgoCD"
  value       = var.argocd_domain
}

output "argocd_cert_issuer" {
  description = "Cert-manager ClusterIssuer for ArgoCD"
  value       = var.argocd_cert_issuer
}

output "argocd_cert_secret_name" {
  description = "TLS secret name for ArgoCD"
  value       = var.argocd_cert_secret_name
}

output "argocd_project_name" {
  description = "ArgoCD AppProject name"
  value       = var.argocd_project_name
}

output "argocd_app_name" {
  description = "ArgoCD Application name"
  value       = var.argocd_app_name
}

output "argocd_app_destination_namespace" {
  description = "Destination namespace for ArgoCD application"
  value       = var.argocd_app_destination_namespace
}

output "argocd_app_source_path" {
  description = "Source path for ArgoCD application"
  value       = var.argocd_app_source_path
}

output "argocd_app_repo_url" {
  description = "Git repository URL for ArgoCD application"
  value       = var.argocd_app_repo_url
}

output "argocd_app_repo_target_revision" {
  description = "Git target revision for ArgoCD application"
  value       = var.argocd_app_repo_target_revision
}

