# =============================================================================
# ECR MODULE - CONTAINER REGISTRY FOR BACKEND
# =============================================================================

# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# ECR REPOSITORY
# =============================================================================

resource "aws_ecr_repository" "backend" {
  name                 = "${var.name_prefix}-backend"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-backend-ecr"
  })
}

# =============================================================================
# ECR LIFECYCLE POLICY
# =============================================================================

resource "aws_ecr_lifecycle_policy" "backend" {
  count      = var.enable_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = var.tag_prefixes
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${var.untagged_expire_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expire_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# =============================================================================
# ECR REPOSITORY POLICY (Optional)
# =============================================================================

resource "aws_ecr_repository_policy" "backend" {
  count      = var.repository_policy != null ? 1 : 0
  repository = aws_ecr_repository.backend.name
  policy     = var.repository_policy
}

# =============================================================================
# IAM ROLE FOR EC2 ECR ACCESS
# =============================================================================

resource "aws_iam_role" "ec2_ecr_role" {
  count = var.create_ec2_role ? 1 : 0
  name  = "${var.name_prefix}-ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# =============================================================================
# IAM POLICY FOR ECR ACCESS
# =============================================================================

resource "aws_iam_role_policy" "ec2_ecr_policy" {
  count = var.create_ec2_role ? 1 : 0
  name  = "${var.name_prefix}-ec2-ecr-policy"
  role  = aws_iam_role.ec2_ecr_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# IAM INSTANCE PROFILE
# =============================================================================

resource "aws_iam_instance_profile" "ec2_ecr_profile" {
  count = var.create_ec2_role ? 1 : 0
  name  = "${var.name_prefix}-ec2-ecr-profile"
  role  = aws_iam_role.ec2_ecr_role[0].name

  tags = var.tags
}
