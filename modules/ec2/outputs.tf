# =============================================================================
# EC2 MODULE OUTPUTS - MINIMAL
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.dev.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.dev.public_ip
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.main.key_name
}

output "private_key_pem" {
  description = "Private key in PEM format"
  value       = tls_private_key.main.private_key_pem
  sensitive   = true
}

output "ssh_connection_command" {
  description = "SSH connection command"
  value       = "ssh -i ${var.name_prefix}-key.pem ubuntu@${aws_instance.dev.public_ip}"
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
}
