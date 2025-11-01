# Data sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Data source to get VPC from remote state
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.terraform_s3_bucket
    key    = "staging/vpc/terraform.tfstate"
    region = var.aws_region
  }
}

# Data source to get VPC details
data "aws_vpc" "main" {
  id = data.terraform_remote_state.vpc.outputs.vpc_id
}

# Data source to get subnets
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-private-*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-public-*"]
  }
}

