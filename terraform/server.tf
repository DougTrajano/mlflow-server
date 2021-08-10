resource "random_password" "mlflow_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_apprunner_service" "server" {
  service_name = "${local.name}"

  source_configuration {
    auto_deployments_enabled = false

    image_repository {
      image_identifier      = "public.ecr.aws/t9j8s4z8/mlflow:latest"
      image_repository_type = "ECR_PUBLIC"

      image_configuration {
        port = local.app_port
        runtime_environment_variables = {
          "MLFLOW_ARTIFACT_URI" = "s3://${aws_s3_bucket.artifact_store.0.id}"
          "MLFLOW_DB_DIALECT" = "mysql+pymysql"
          "MLFLOW_DB_USERNAME" = "${aws_db_instance.backend_store.username}"
          "MLFLOW_DB_PASSWORD" = "${random_password.backend_store.result}"
          "MLFLOW_DB_HOST" = "${aws_db_instance.backend_store.address}"
          "MLFLOW_DB_PORT" = "${aws_db_instance.backend_store.port}"
          "MLFLOW_DB_DATABASE" = "${aws_db_instance.backend_store.name}"
          "MLFLOW_TRACKING_USERNAME" = var.mlflow_username
          "MLFLOW_TRACKING_PASSWORD" = local.mlflow_password
          }
        }    
      }
  }

  instance_configuration {
    cpu = var.service_cpu
    memory = var.service_memory
    instance_role_arn = aws_iam_role.iam_role.arn
  }

  tags = merge(
    {
        Name = "${local.name}"
    },
    local.tags
  )
}