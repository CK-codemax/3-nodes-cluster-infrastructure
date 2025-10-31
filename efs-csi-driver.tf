# Data source to get default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get subnet IDs
data "aws_subnet" "default" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

# Get the first two availability zones' subnets for mount targets
locals {
  subnet_ids = [for s in data.aws_subnet.default : s.id]
  # Use first two subnets for mount targets
  mount_target_subnets = slice(local.subnet_ids, 0, min(2, length(local.subnet_ids)))
}

# Variable for EFS creation token
variable "efs_creation_token" {
  description = "Creation token for EFS file system"
  type        = string
  default     = "k8s-efs"
}

# Create EFS file system
resource "aws_efs_file_system" "eks" {
  creation_token   = "${var.environment}-${var.cluster_name}-${var.efs_creation_token}"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  tags = {
    Name        = "${var.cluster_name}-efs"
    Environment = var.environment
  }
}

# Create EFS mount targets for each subnet
resource "aws_efs_mount_target" "mount_targets" {
  for_each = toset(local.mount_target_subnets)

  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = each.value
  security_groups = [aws_security_group.workers.id]

  depends_on = [aws_efs_file_system.eks]
}

# Security group rule for EFS access from workers
resource "aws_security_group_rule" "efs_ingress_workers" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.workers.id
  source_security_group_id = aws_security_group.workers.id
  description              = "Allow EFS access from worker nodes"
}

# Security group rule for EFS access from masters
resource "aws_security_group_rule" "efs_ingress_masters" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.workers.id
  source_security_group_id = aws_security_group.masters.id
  description              = "Allow EFS access from master nodes"
}

# IAM Policy Document for EFS CSI Driver
# Note: For self-managed Kubernetes clusters, using similar pattern to other CSI drivers
data "aws_iam_policy_document" "efs_csi_driver_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# IAM Role for EFS CSI Driver
resource "aws_iam_role" "efs_csi_driver" {
  name               = "${var.environment}-${var.cluster_name}-efs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_driver_assume_role.json

  tags = {
    Name        = "${var.cluster_name}-efs-csi-driver-role"
    Description = "IAM role for EFS CSI Driver"
  }
}

# Attach the AWS-managed EFS CSI Driver Policy
resource "aws_iam_role_policy_attachment" "efs_csi_driver_policy" {
  role       = aws_iam_role.efs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"

  depends_on = [aws_iam_role.efs_csi_driver]
}

# Outputs for Ansible playbook
output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.eks.id
}

output "efs_file_system_dns_name" {
  description = "EFS file system DNS name"
  value       = aws_efs_file_system.eks.dns_name
}

output "efs_csi_driver_role_arn" {
  description = "ARN of the IAM role for EFS CSI Driver"
  value       = aws_iam_role.efs_csi_driver.arn
}

output "efs_csi_driver_role_name" {
  description = "Name of the IAM role for EFS CSI Driver"
  value       = aws_iam_role.efs_csi_driver.name
}

output "efs_mount_target_subnets" {
  description = "Subnet IDs used for EFS mount targets"
  value       = local.mount_target_subnets
}

