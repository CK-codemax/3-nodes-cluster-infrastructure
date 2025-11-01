# IAM Policy for AWS Load Balancer Controller
# This policy is attached to the combined AWS workloads instance profile
resource "aws_iam_policy" "aws_lbc" {
  name        = var.aws_lbc_policy_name != "" ? var.aws_lbc_policy_name : "${var.env}-${var.cluster_name}-AWSLoadBalancerController"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam/AWSLoadBalancerController.json")

  tags = {
    Name = var.aws_lbc_policy_tag_name != "" ? var.aws_lbc_policy_tag_name : "${var.cluster_name}-aws-lbc-policy"
  }
}

