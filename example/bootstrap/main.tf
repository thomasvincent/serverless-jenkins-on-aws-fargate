data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  tags = {
    team     = "devops"
    solution = "jenkins"
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = var.state_lock_table_name
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(local.tags, {
    Name = "DynamoDB Terraform State Lock Table"
  })
}
