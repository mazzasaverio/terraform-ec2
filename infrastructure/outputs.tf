# =============================================================================
# ROOT OUTPUTS - SECURE VERSION
# =============================================================================

output "instance_public_ip" {
  description = "Public IP address of the development server"
  value       = module.ec2.instance_public_ip
}

output "ssh_connection_command" {
  description = "SSH connection command using secure external key"
  value       = "ssh -i .ssh/terraform-ec2-key ubuntu@${module.ec2.instance_public_ip}"
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.ec2.instance_public_dns
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.ec2.security_group_id
}

output "key_name" {
  description = "AWS key pair name"
  value       = module.ec2.key_name
}

# =============================================================================
# INFRASTRUCTURE OUTPUTS
# =============================================================================

# =============================================================================
# VPC OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

# =============================================================================
# S3 OUTPUTS
# =============================================================================

output "app_bucket_name" {
  description = "Name of the application data S3 bucket"
  value       = module.s3.app_bucket_name
}

output "app_bucket_arn" {
  description = "ARN of the application data S3 bucket"
  value       = module.s3.app_bucket_arn
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = module.s3.logs_bucket_name
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket"
  value       = module.s3.logs_bucket_arn
}

# =============================================================================
# ECR OUTPUTS
# =============================================================================

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.repository_name
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = module.ecr.repository_arn
}

# =============================================================================
# REGIONAL INFORMATION
# =============================================================================

output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# =============================================================================
# IAM OUTPUTS
# =============================================================================

output "ec2_iam_role_arn" {
  description = "ARN of the EC2 IAM role for S3 access"
  value       = module.s3.instance_profile_arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = module.s3.instance_profile_name
}
