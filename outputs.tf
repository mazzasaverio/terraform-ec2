# =============================================================================
# ROOT OUTPUTS - MINIMAL ESSENTIALS
# =============================================================================

output "instance_public_ip" {
  description = "Public IP address of the development server"
  value       = module.ec2.instance_public_ip
}

output "ssh_command" {
  description = "SSH connection command"
  value       = "ssh -i ${var.project_name}-key.pem ubuntu@${module.ec2.instance_public_ip}"
}

output "private_key_pem" {
  description = "Private SSH key (save this!)"
  value       = module.ec2.private_key_pem
  sensitive   = true
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}
