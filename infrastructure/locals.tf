# =============================================================================
# LOCAL VALUES - CALCULATED AUTOMATICALLY
# =============================================================================

locals {
  # Resource naming convention
  name_prefix = "${var.project_name}-${var.environment}"

  # Use provided availability zones or get available ones
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names

  # Network configuration (can be overridden in variables if needed)
  vpc_cidr = "10.0.0.0/16"

  public_subnet_cidrs = [
    "10.0.1.0/24", # Public subnet 1
    "10.0.2.0/24"  # Public subnet 2
  ]

  private_subnet_cidrs = [
    "10.0.10.0/24", # Private subnet 1
    "10.0.20.0/24"  # Private subnet 2
  ]

  # Standard tags applied to all resources
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "terraform"
      CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    },
    var.additional_tags
  )
}
