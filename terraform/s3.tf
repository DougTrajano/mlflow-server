resource "aws_s3_bucket_versioning" "versioning" {
  count  = local.create_dedicated_bucket ? 1 : 0
  bucket = aws_s3_bucket.mlflow_artifact_store.0.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "bucket_lifecycle" {
  count  = local.create_dedicated_bucket ? 1 : 0
  name   = "${local.name}-bucket-lifecycle"
  bucket = aws_s3_bucket.mlflow_artifact_store.0.bucket

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  count  = local.create_dedicated_bucket ? 1 : 0
  bucket = aws_s3_bucket.mlflow_artifact_store.0.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  count  = local.create_dedicated_bucket ? 1 : 0
  bucket = aws_s3_bucket.mlflow_artifact_store.0.id
  acl    = "private"
}

resource "aws_s3_bucket" "mlflow_artifact_store" {
  count         = local.create_dedicated_bucket ? 1 : 0
  bucket_prefix = "${local.name}-"

  tags = merge(
    {
        Name = "${local.name}-bucket"
    },
    local.tags
  )
}