# Use private subnets from VPC remote state for EFS mount targets
locals {
  mount_target_subnets = data.terraform_remote_state.vpc.outputs.private_subnet_ids
}

# Create EFS file system
resource "aws_efs_file_system" "eks" {
  creation_token   = var.efs_creation_token != "" ? "${var.env}-${var.cluster_name}-${var.efs_creation_token}" : "${var.env}-${var.cluster_name}-efs"
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode
  encrypted        = var.efs_encrypted

  tags = {
    Name        = var.efs_file_system_name != "" ? var.efs_file_system_name : "${var.cluster_name}-efs"
    Environment = var.env
  }
}

# Create security group for EFS
resource "aws_security_group" "efs" {
  name_prefix = "${var.cluster_name}-efs-"
  vpc_id      = data.aws_vpc.main.id
  description = "Security group for EFS file system"

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.masters.id, aws_security_group.workers.id]
    description     = "Allow EFS access from master and worker nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-efs-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create EFS mount targets for each subnet
resource "aws_efs_mount_target" "mount_targets" {
  for_each = toset(local.mount_target_subnets)

  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]

  depends_on = [aws_efs_file_system.eks]
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
  name               = var.efs_csi_driver_role_name != "" ? var.efs_csi_driver_role_name : "${var.env}-${var.cluster_name}-efs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_driver_assume_role.json

  tags = {
    Name        = var.efs_csi_driver_role_tag_name != "" ? var.efs_csi_driver_role_tag_name : "${var.cluster_name}-efs-csi-driver-role"
    Description = var.efs_csi_driver_role_tag_description
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

output "efs_security_group_id" {
  description = "Security group ID for EFS"
  value       = aws_security_group.efs.id
}

