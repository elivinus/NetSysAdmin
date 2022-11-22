data "aws_caller_identity" "current" {}

locals {
  default_lifecycle_policy = {
    rules = [{
      rulePriority = 1
      description  = "Expire untagged images older than 31 days"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 31
      }
      action = {
        type = "expire"
      }
    },
    {
      rulePriority = 2
      description  = "Keep last 30 dev images"
      selection = {
        tagStatus   = "tagged"
        tagPrefixList = ["dev"],
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  }
}


locals {
  # Encryption configuration
  # If encryption type is not KMS, use assigned key or otherwise build a new key
  encryption_configuration = var.encryption_type != "KMS" ? [] : [
    {
      encryption_type = "KMS"
      kms_key         = var.encryption_type == "KMS" && var.kms_key == null ? aws_kms_key.kms_key[0].arn : var.kms_key
    }
  ]


  # Timeouts
  # If no timeouts block is provided, build one using the default values
  timeouts = var.timeouts_delete == null && length(var.timeouts) == 0 ? [] : [
    {
      delete = lookup(var.timeouts, "delete", null) == null ? var.timeouts_delete : lookup(var.timeouts, "delete")
    }
  ]
}

resource "aws_ecr_repository" "repo" {
  for_each = toset(var.repository_list)
  name = each.key
  image_tag_mutability = var.image_tag_mutability

  # Encryption configuration
  dynamic "encryption_configuration" {
    for_each = local.encryption_configuration
    content {
      encryption_type = lookup(encryption_configuration.value, "encryption_type")
      kms_key         = lookup(encryption_configuration.value, "kms_key")
    }
  }

  # Image scanning configuration
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }


  # Timeouts
  dynamic "timeouts" {
    for_each = local.timeouts
    content {
      delete = lookup(timeouts.value, "delete")
    }
  }

  # Tags
  tags = tomap({
    "Name" = "ogtl-ecr"
  })
}

# Policy
resource "aws_ecr_repository_policy" "policy" {
  for_each = aws_ecr_repository.repo
  repository = each.value.name
  # count      = var.policy == null ? 0 : 1
  # repository = aws_ecr_repository.repo[each.key]
  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:DescribeImages",
                "ecr:GetAuthorizationToken",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}


# Lifecycle policy
resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  # count      = var.lifecycle_policy == null ? 0 : 1
  for_each = aws_ecr_repository.repo
  repository = each.value.name
  policy     = var.lifecycle_policy == null ? jsonencode(local.default_lifecycle_policy) : var.lifecycle_policy
  depends_on = [
    aws_ecr_repository.repo
  ]
}

# KMS key
resource "aws_kms_key" "kms_key" {
  count       = var.encryption_type == "KMS" && var.kms_key == null ? 1 : 0
  # description = "${var.repo-name} KMS key"
}

resource "aws_kms_alias" "kms_key_alias" {
  count         = var.encryption_type == "KMS" && var.kms_key == null ? 1 : 0
  name          = "alias/ogtl-Key"
  target_key_id = aws_kms_key.kms_key[0].key_id
}
