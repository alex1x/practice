provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  name = "practice"
  cidr = "10.0.188.0/24"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnets  = ["10.0.188.0/26"]
  private_subnets = ["10.0.188.64/26", "10.0.188.128/26", "10.0.188.192/26"]

  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false
}

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.31"

#   cluster_name    = "example"
#   cluster_version = "1.31"

#   cluster_endpoint_public_access = true

#   enable_cluster_creator_admin_permissions = true

#   cluster_compute_config = {
#     enabled    = true
#     node_pools = ["general-purpose"]
#   }

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets

#   eks_managed_node_groups = {
#     example = {
#       ami_type       = "AL2023_x86_64_STANDARD"
#       instance_types = ["m7i.large"]

#       min_size     = 1
#       max_size     = 10
#       desired_size = 1
#     }
#   }

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }

# output "cluster_endpoint" {
#   value = module.eks.cluster_endpoint
# }

# output "cluster_security_group_id" {
#   value = module.eks.cluster_security_group_id
# }