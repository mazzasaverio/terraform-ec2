# =============================================================================
# MAIN CONFIGURATION
# =============================================================================

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Data source for current AWS region
data "aws_region" "current" {}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# =============================================================================
# VPC MODULE
# =============================================================================

module "vpc" {
  source = "./modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr             = local.vpc_cidr
  availability_zones   = local.availability_zones
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs

  tags = local.common_tags
}

# =============================================================================
# ECR MODULE
# =============================================================================

module "ecr" {
  source = "./modules/ecr"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}

# =============================================================================
# EC2 MODULE
# =============================================================================

module "ec2" {
  source = "./modules/ec2"

  name_prefix               = local.name_prefix
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  ssh_public_key            = var.ssh_public_key
  iam_instance_profile_name = module.ecr.instance_profile_name

  tags = local.common_tags
}
