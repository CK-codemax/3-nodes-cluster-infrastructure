terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    region       = ""
    bucket       = ""
    key          = "staging/k8s-cluster/terraform.tfstate"
    encrypt      = true
    dynamodb_table = ""
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "3-nodes-Kubernetes-Cluster"
      Environment = var.env
      ManagedBy   = "Terraform"
      CreatedBy   = "Ochuko Whoro"
      Purpose     = "Learning and Testing"
    }
  }
}

