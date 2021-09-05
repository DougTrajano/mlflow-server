resource "aws_s3_bucket" "artifact_store" {
  count         = local.create_dedicated_bucket ? 1 : 0
  bucket_prefix = "${local.name}-"
  acl           = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "history"
    enabled = true
    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

  tags = merge(
    {
        Name = "${local.name}-bucket"
    },
    local.tags
  )
}