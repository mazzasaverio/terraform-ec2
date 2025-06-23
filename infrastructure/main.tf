# =============================================================================
# MAIN CONFIGURATION - TEST MODULO VPC
# =============================================================================

# Provider è già definito in versions.tf

# =============================================================================
# VPC MODULE
# =============================================================================

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

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
# EC2 MODULE - WITH SECURE SSH KEY HANDLING
# =============================================================================

module "ec2" {
  source = "./modules/ec2"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  ssh_public_key    = var.ssh_public_key # Now using external SSH key

  tags = local.common_tags
}
