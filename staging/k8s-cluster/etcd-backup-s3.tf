# S3 Bucket for etcd Backups
resource "aws_s3_bucket" "etcd_backup" {
  bucket = "${var.env}-${var.cluster_name}-etcd-backup"

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "${var.cluster_name}-etcd-backup"
    Environment = var.env
    Purpose     = "etcd-backup"
  }
}

# Enable versioning for etcd backups
resource "aws_s3_bucket_versioning" "etcd_backup" {
  bucket = aws_s3_bucket.etcd_backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for etcd backups
resource "aws_s3_bucket_server_side_encryption_configuration" "etcd_backup" {
  bucket = aws_s3_bucket.etcd_backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for etcd backups
resource "aws_s3_bucket_public_access_block" "etcd_backup" {
  bucket = aws_s3_bucket.etcd_backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for etcd backups (optional - keep backups for 90 days)
resource "aws_s3_bucket_lifecycle_configuration" "etcd_backup" {
  bucket = aws_s3_bucket.etcd_backup.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    filter {}

    expiration {
      days = var.etcd_backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.etcd_backup_retention_days
    }
  }
}

# IAM Policy for etcd backup access
data "aws_iam_policy_document" "etcd_backup" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.etcd_backup.arn,
      "${aws_s3_bucket.etcd_backup.arn}/*"
    ]
  }
}

# IAM Policy for etcd backup
resource "aws_iam_policy" "etcd_backup" {
  name        = var.etcd_backup_policy_name != "" ? var.etcd_backup_policy_name : "${var.env}-${var.cluster_name}-etcd-backup-policy"
  description = "IAM policy for etcd backup to S3"
  policy      = data.aws_iam_policy_document.etcd_backup.json

  tags = {
    Name        = var.etcd_backup_policy_tag_name != "" ? var.etcd_backup_policy_tag_name : "${var.cluster_name}-etcd-backup-policy"
    Description = "IAM policy for etcd backup"
  }
}

# IAM Role for etcd backup (to be attached to master nodes)
resource "aws_iam_role" "etcd_backup" {
  name = var.etcd_backup_role_name != "" ? var.etcd_backup_role_name : "${var.env}-${var.cluster_name}-etcd-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = var.etcd_backup_role_tag_name != "" ? var.etcd_backup_role_tag_name : "${var.cluster_name}-etcd-backup-role"
    Description = var.etcd_backup_role_tag_description
  }
}

# Attach etcd backup policy to role
resource "aws_iam_role_policy_attachment" "etcd_backup" {
  role       = aws_iam_role.etcd_backup.name
  policy_arn = aws_iam_policy.etcd_backup.arn
}

# Attach AWS Load Balancer Controller policy to etcd_backup role (for master nodes)
# This allows master nodes to create AWS load balancers for services with AWS annotations
resource "aws_iam_role_policy_attachment" "etcd_backup_aws_lbc" {
  role       = aws_iam_role.etcd_backup.name
  policy_arn = aws_iam_policy.aws_lbc.arn

  depends_on = [
    aws_iam_role.etcd_backup,
    aws_iam_policy.aws_lbc
  ]
}

# Instance profile for etcd backup (to attach to master nodes)
resource "aws_iam_instance_profile" "etcd_backup" {
  name = var.etcd_backup_instance_profile_name != "" ? var.etcd_backup_instance_profile_name : "${var.env}-${var.cluster_name}-etcd-backup-profile"
  role = aws_iam_role.etcd_backup.name

  tags = {
    Name = "${var.cluster_name}-etcd-backup-instance-profile"
  }
}

