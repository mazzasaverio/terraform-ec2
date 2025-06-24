# =============================================================================
# ECR MODULE OUTPUTS
# =============================================================================

# =============================================================================
# ECR REPOSITORY OUTPUTS
# =============================================================================

output "repository_arn" {
  description = "Full ARN of the repository"
  value       = aws_ecr_repository.backend.arn
}

output "repository_name" {
  description = "Name of the repository"
  value       = aws_ecr_repository.backend.name
}

output "repository_url" {
  description = "URL of the repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "registry_id" {
  description = "Registry ID where the repository was created"
  value       = aws_ecr_repository.backend.registry_id
}

# =============================================================================
# IAM OUTPUTS
# =============================================================================

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 ECR access"
  value       = var.create_ec2_role ? aws_iam_role.ec2_ecr_role[0].arn : null
}

output "iam_role_name" {
  description = "Name of the IAM role for EC2 ECR access"
  value       = var.create_ec2_role ? aws_iam_role.ec2_ecr_role[0].name : null
}

output "instance_profile_arn" {
  description = "ARN of the instance profile"
  value       = var.create_ec2_role ? aws_iam_instance_profile.ec2_ecr_profile[0].arn : null
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = var.create_ec2_role ? aws_iam_instance_profile.ec2_ecr_profile[0].name : null
}

# =============================================================================
# COMPUTED VALUES
# =============================================================================

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}
