output "artifact_bucket_id" {
  value = local.artifact_bucket_id
}

output "service_url" {
  value = "https://${aws_apprunner_service.mlflow_server.service_url}"
}

output "mlflow_username" {
  value = var.mlflow_username
}

output "mlflow_password" {
  value = local.mlflow_password
  sensitive = true
}

output "status" {
  value = aws_apprunner_service.mlflow_server.status
}