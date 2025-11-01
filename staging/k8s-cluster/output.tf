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
  value       = var.env
}

output "vpc_id" {
  description = "VPC ID"
  value       = data.aws_vpc.main.id
}

# etcd Backup Outputs
output "etcd_backup_bucket_name" {
  description = "Name of the S3 bucket for etcd backups"
  value       = aws_s3_bucket.etcd_backup.bucket
}

output "etcd_backup_bucket_arn" {
  description = "ARN of the S3 bucket for etcd backups"
  value       = aws_s3_bucket.etcd_backup.arn
}

output "etcd_backup_role_arn" {
  description = "ARN of the IAM role for etcd backup"
  value       = aws_iam_role.etcd_backup.arn
}

output "etcd_backup_role_name" {
  description = "Name of the IAM role for etcd backup"
  value       = aws_iam_role.etcd_backup.name
}

output "etcd_backup_instance_profile_name" {
  description = "Name of the IAM instance profile for etcd backup"
  value       = aws_iam_instance_profile.etcd_backup.name
}

