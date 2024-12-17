provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Environment = "dev"
      Terraform   = "true"
      Project     = "practice"
      Owner       = "alex1x"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  cluster_name = "practice"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = local.cluster_name
  cluster_version = "1.31"

  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "practice"
    Owner       = "alex1x"
  }
}

resource "aws_dynamodb_table" "practice" {
  name = "practice"
  hash_key = "id"
  attribute {
    name = "id"
    type = "S"
  }
  billing_mode = "PAY_PER_REQUEST"
}

resource "null_resource" "tag_subnets" {
  for_each = toset(data.aws_subnets.default.ids)

  provisioner "local-exec" {
    command = <<EOT
      aws ec2 create-tags --resources ${each.key} --tags Key=kubernetes.io/role/elb,Value=1 Key=kubernetes.io/cluster/${local.cluster_name},Value=shared
    EOT
  }
}