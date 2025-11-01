# IAM Policy Document for EBS CSI Driver
# Note: For self-managed Kubernetes clusters, you may need to configure OIDC provider
# For now, using similar pattern to AWS Load Balancer Controller
data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
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

# IAM Role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver" {
  name               = var.ebs_csi_driver_role_name != "" ? var.ebs_csi_driver_role_name : "${var.environment}-${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json

  tags = {
    Name        = var.ebs_csi_driver_role_tag_name != "" ? var.ebs_csi_driver_role_tag_name : "${var.cluster_name}-ebs-csi-driver-role"
    Description = var.ebs_csi_driver_role_tag_description
  }
}

# Attach the AWS-managed EBS CSI Driver Policy
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

  depends_on = [aws_iam_role.ebs_csi_driver]
}

# Output the IAM Role ARN for use in Ansible playbook
output "ebs_csi_driver_role_arn" {
  description = "ARN of the IAM role for EBS CSI Driver"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "ebs_csi_driver_role_name" {
  description = "Name of the IAM role for EBS CSI Driver"
  value       = aws_iam_role.ebs_csi_driver.name
}

