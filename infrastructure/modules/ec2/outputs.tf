# =============================================================================
# EC2 MODULE OUTPUTS
# =============================================================================

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.dev_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.dev_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.dev_server.public_dns
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.dev_server.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.dev.id
}

output "key_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.main.key_name
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance using the generated private key"
  value       = "ssh -i .ssh/terraform-ec2-key ubuntu@${aws_instance.dev_server.public_ip}"
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}
