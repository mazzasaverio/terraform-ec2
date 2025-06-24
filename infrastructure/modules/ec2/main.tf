# =============================================================================
# EC2 MODULE - SIMPLIFIED DEVELOPMENT SERVER
# =============================================================================

# Data source for current AWS region
data "aws_region" "current" {}

# Data source to get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# =============================================================================
# SECURITY GROUP
# =============================================================================

resource "aws_security_group" "dev" {
  name_prefix = "${var.name_prefix}-dev-"
  vpc_id      = var.vpc_id
  description = "Security group for development server"

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP for testing
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS for testing
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Development ports (8000-8999) - includes FastAPI
  ingress {
    description = "Development Ports"
    from_port   = 8000
    to_port     = 8999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-dev-sg"
    Type = "SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# SSH KEY PAIR - SECURE VERSION (NO PRIVATE KEY IN STATE)
# =============================================================================

resource "aws_key_pair" "main" {
  key_name   = "${var.name_prefix}-key"
  public_key = var.ssh_public_key

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-key"
    Type = "KeyPair"
  })
}

# =============================================================================
# USER DATA SCRIPT
# =============================================================================

locals {
  user_data = base64encode(templatefile("${path.module}/dev-setup.sh", {
    project_name = var.name_prefix
    username     = var.dev_username
  }))
}

# =============================================================================
# EC2 INSTANCE
# =============================================================================

resource "aws_instance" "dev_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.dev.id]
  subnet_id              = var.public_subnet_ids[0]

  # IAM instance profile for ECR access
  iam_instance_profile = var.iam_instance_profile_name

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    aws_region = data.aws_region.current.name
    name_prefix = var.name_prefix
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(var.tags, {
      Name = "${var.name_prefix}-root-volume"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-dev-server"
  })
}
