# Data source to get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source to get the EKS cluster (if using EKS)
# Note: For self-managed Kubernetes clusters, you may need to configure IRSA differently
# Uncomment and adapt if using EKS
# data "aws_eks_cluster" "eks" {
#   name = "${var.env}-${var.cluster_name}"
# }

# IAM Policy Document for AWS Load Balancer Controller
data "aws_iam_policy_document" "aws_lbc" {
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

# IAM Role for AWS Load Balancer Controller
resource "aws_iam_role" "aws_lbc" {
  name               = var.aws_lbc_role_name != "" ? var.aws_lbc_role_name : "${var.env}-${var.cluster_name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json

  tags = {
    Name        = var.aws_lbc_role_tag_name != "" ? var.aws_lbc_role_tag_name : "${var.cluster_name}-aws-lbc-role"
    Description = var.aws_lbc_role_tag_description
  }
}

# IAM Policy for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_lbc" {
  name        = var.aws_lbc_policy_name != "" ? var.aws_lbc_policy_name : "${var.env}-${var.cluster_name}-AWSLoadBalancerController"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam/AWSLoadBalancerController.json")

  tags = {
    Name = var.aws_lbc_policy_tag_name != "" ? var.aws_lbc_policy_tag_name : "${var.cluster_name}-aws-lbc-policy"
  }
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name

  depends_on = [aws_iam_role.aws_lbc, aws_iam_policy.aws_lbc]
}

# EKS Pod Identity Association for AWS Load Balancer Controller
# Note: This is EKS-specific. For self-managed clusters, you'll need to:
# 1. Configure IRSA by setting up OIDC provider and annotating the service account
# 2. Or use instance profiles on the worker nodes
# Uncomment if using EKS:
# resource "aws_eks_pod_identity_association" "aws_lbc" {
#   cluster_name    = "${var.env}-${var.cluster_name}"
#   namespace       = "aws-load-balancer-controller"
#   service_account = "aws-load-balancer-controller"
#   role_arn        = aws_iam_role.aws_lbc.arn
#
#   depends_on = [aws_iam_role.aws_lbc]
# }

# Output the IAM Role ARN for use in Ansible playbook
output "aws_lbc_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_lbc.arn
}

output "aws_lbc_role_name" {
  description = "Name of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_lbc.name
}

