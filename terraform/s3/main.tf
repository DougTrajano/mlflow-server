resource "aws_s3_bucket_versioning" "versioning" {
  count  = var.create_dedicated_bucket ? 1 : 0
  bucket = aws_s3_bucket.mlflow_artifact_store.0.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "bucket_lifecycle" {
  count  = var.create_dedicated_bucket ? 1 : 0
  name   = "${var.name}-bucket-lifecycle"
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
  count  = var.create_dedicated_bucket ? 1 : 0
  bucket = aws_s3_bucket.mlflow_artifact_store.0.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  count  = var.create_dedicated_bucket ? 1 : 0
  bucket = aws_s3_bucket.mlflow_artifact_store.0.id
  acl    = "private"
}

resource "aws_s3_bucket" "mlflow_artifact_store" {
  count         = var.create_dedicated_bucket ? 1 : 0
  bucket_prefix = "${var.name}-"
  force_destroy = true

  tags = merge(
    {
        Name = "${var.name}-bucket"
    },
    var.tags
  )
}