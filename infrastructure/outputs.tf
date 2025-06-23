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
