# =============================================================================
# ECR MODULE VARIABLES
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# ECR REPOSITORY CONFIGURATION
# =============================================================================

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "The encryption type to use for the repository"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either AES256 or KMS."
  }
}

variable "kms_key_id" {
  description = "The KMS key ID to use for encryption (only if encryption_type is KMS)"
  type        = string
  default     = null
}

# =============================================================================
# LIFECYCLE POLICY CONFIGURATION
# =============================================================================

variable "enable_lifecycle_policy" {
  description = "Enable ECR lifecycle policy"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of images to keep"
  type        = number
  default     = 10
}

variable "tag_prefixes" {
  description = "List of tag prefixes to apply lifecycle policy to"
  type        = list(string)
  default     = ["v", "release", "latest"]
}

variable "untagged_expire_days" {
  description = "Number of days after which untagged images expire"
  type        = number
  default     = 1
}

# =============================================================================
# REPOSITORY POLICY
# =============================================================================

variable "repository_policy" {
  description = "ECR repository policy JSON"
  type        = string
  default     = null
}

# =============================================================================
# IAM CONFIGURATION
# =============================================================================

variable "create_ec2_role" {
  description = "Whether to create IAM role for EC2 ECR access"
  type        = bool
  default     = true
}
