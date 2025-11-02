# IAM Role for AWS VPC CNI (for all worker nodes)
# This role only has AmazonEKS_CNI_Policy

data "aws_iam_policy_document" "aws_cni_instance_profile" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

# IAM Role for AWS VPC CNI (instance profile)
resource "aws_iam_role" "aws_cni_instance_profile" {
  name               = "${var.env}-${var.cluster_name}-aws-cni-instance-profile"
  assume_role_policy = data.aws_iam_policy_document.aws_cni_instance_profile.json

  tags = {
    Name        = "${var.cluster_name}-aws-cni-instance-profile-role"
    Description = "IAM role for AWS VPC CNI only"
  }
}

# Attach AmazonEKS_CNI_Policy for AWS VPC CNI
resource "aws_iam_role_policy_attachment" "aws_cni" {
  role       = aws_iam_role.aws_cni_instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

  depends_on = [aws_iam_role.aws_cni_instance_profile]
}

# Instance profile for AWS CNI (attached to all worker nodes)
resource "aws_iam_instance_profile" "aws_cni" {
  name = "${var.env}-${var.cluster_name}-aws-cni-instance-profile"
  role = aws_iam_role.aws_cni_instance_profile.name

  tags = {
    Name = "${var.cluster_name}-aws-cni-instance-profile"
  }
}

# Combined IAM Role for AWS workloads (for worker1 only)
# This role combines permissions for:
# - AmazonEKS_CNI_Policy (for AWS VPC CNI)
# - AWS Load Balancer Controller
# - EBS CSI Driver
# - EFS CSI Driver
# - etcd Backup

data "aws_iam_policy_document" "aws_workloads_instance_profile" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

# Combined IAM Role for AWS workloads (instance profile)
resource "aws_iam_role" "aws_workloads_instance_profile" {
  name               = "${var.env}-${var.cluster_name}-aws-workloads-instance-profile"
  assume_role_policy = data.aws_iam_policy_document.aws_workloads_instance_profile.json

  tags = {
    Name        = "${var.cluster_name}-aws-workloads-instance-profile-role"
    Description = "Combined IAM role for all AWS workloads self-managed cluster (worker1 only)"
  }
}

# Attach AmazonEKS_CNI_Policy for AWS VPC CNI (worker1 also needs this)
resource "aws_iam_role_policy_attachment" "aws_workloads_cni" {
  role       = aws_iam_role.aws_workloads_instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

  depends_on = [aws_iam_role.aws_workloads_instance_profile]
}

# Attach AWS Load Balancer Controller policy
resource "aws_iam_role_policy_attachment" "aws_workloads_lbc" {
  role       = aws_iam_role.aws_workloads_instance_profile.name
  policy_arn = aws_iam_policy.aws_lbc.arn

  depends_on = [aws_iam_role.aws_workloads_instance_profile, aws_iam_policy.aws_lbc]
}

# Attach EBS CSI Driver policy
resource "aws_iam_role_policy_attachment" "aws_workloads_ebs_csi" {
  role       = aws_iam_role.aws_workloads_instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

  depends_on = [aws_iam_role.aws_workloads_instance_profile]
}

# Attach EFS CSI Driver policy
resource "aws_iam_role_policy_attachment" "aws_workloads_efs_csi" {
  role       = aws_iam_role.aws_workloads_instance_profile.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"

  depends_on = [aws_iam_role.aws_workloads_instance_profile]
}

# Attach etcd backup policy
resource "aws_iam_role_policy_attachment" "aws_workloads_etcd_backup" {
  role       = aws_iam_role.aws_workloads_instance_profile.name
  policy_arn = aws_iam_policy.etcd_backup.arn

  depends_on = [aws_iam_role.aws_workloads_instance_profile, aws_iam_policy.etcd_backup]
}

# Instance profile for AWS workloads (attached to worker nodes)
resource "aws_iam_instance_profile" "aws_workloads" {
  name = "${var.env}-${var.cluster_name}-aws-workloads-instance-profile"
  role = aws_iam_role.aws_workloads_instance_profile.name

  tags = {
    Name = "${var.cluster_name}-aws-workloads-instance-profile"
  }
}

