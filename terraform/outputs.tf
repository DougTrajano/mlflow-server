output "artifact_bucket_id" {
  value = aws_s3_bucket.artifact_store.0.id
}

output "service_url" {
  value = aws_apprunner_service.server.service_url
}

output "port" {
  value = local.app_port
}

output "mlflow_username" {
  value = var.mlflow_username
}

output "mlflow_password" {
  value = local.mlflow_password
  sensitive = true
}

output "status" {
  value = aws_apprunner_service.server.status
}