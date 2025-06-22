# =============================================================================
# EC2 MODULE VARIABLES - SIMPLIFIED
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where resources will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where EC2 instance will be placed"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_ids) > 0
    error_message = "At least one public subnet ID must be provided."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.large"

  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge",
      "t3a.micro", "t3a.small", "t3a.medium", "t3a.large", "t3a.xlarge",
      "m5.large", "m5.xlarge", "c5.large", "c5.xlarge"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "ami_id" {
  description = "AMI ID to use for instance (if empty, latest Ubuntu LTS will be used)"
  type        = string
  default     = ""
}

variable "dev_username" {
  description = "Username for development user (will be created with sudo access)"
  type        = string
  default     = "dev"

  validation {
    condition     = length(var.dev_username) > 0 && can(regex("^[a-z][a-z0-9_-]*$", var.dev_username))
    error_message = "Username must start with a letter and contain only lowercase letters, numbers, underscore, and hyphen."
  }
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be gp2, gp3, io1, or io2."
  }
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 20 and 100 GB."
  }
}

variable "root_volume_encrypted" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}
