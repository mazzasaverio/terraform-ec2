# =============================================================================
# S3 MODULE OUTPUTS
# =============================================================================

output "app_bucket_name" {
  description = "Name of the application data S3 bucket"
  value       = aws_s3_bucket.app_bucket.bucket
}

output "app_bucket_arn" {
  description = "ARN of the application data S3 bucket"
  value       = aws_s3_bucket.app_bucket.arn
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.logs_bucket.bucket
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket"
  value       = aws_s3_bucket.logs_bucket.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 access"
  value       = aws_iam_instance_profile.ec2_access_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile for EC2 access"
  value       = aws_iam_instance_profile.ec2_access_profile.arn
}

output "access_policy_arn" {
  description = "ARN of the EC2 access policy"
  value       = aws_iam_policy.ec2_access_policy.arn
} 