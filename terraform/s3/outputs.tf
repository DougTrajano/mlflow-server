output "artifact_bucket_id" {
  value = aws_s3_bucket.mlflow_artifact_store.0.id
}

output "artifact_bucket_arn" {
  value = aws_s3_bucket.mlflow_artifact_store.*.arn
}