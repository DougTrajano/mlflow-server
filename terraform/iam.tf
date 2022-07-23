resource "aws_iam_role" "mlflow_iam_role" {
  name = "${local.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Effect = "Allow"
      },
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })

  tags = merge(
    {
        Name = "${local.name}-role"
    },
    local.tags
  )
}

resource "aws_iam_role_policy" "mlflow_bucket_policy" {
  count       = local.create_dedicated_bucket ? 1 : 0
  name_prefix = "access_to_mlflow_bucket"
  role        = aws_iam_role.mlflow_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:HeadBucket",
        ]
        Resource = concat(
          module.s3.artifact_bucket_arn,
        )
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucketMultipartUploads",
          "s3:GetBucketTagging",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateTags",
          "s3:PutObjectVersionTagging",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:AbortMultipartUpload",
          "s3:PutBucketTagging",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:GetObjectVersion",
        ]
        Resource = [
          for bucket in concat(module.s3.artifact_bucket_arn) :
          "${bucket}/*"
        ]
      },
    ]
  })
}