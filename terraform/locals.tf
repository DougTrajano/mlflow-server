locals {
    # General
    name = "${var.name}-${var.environment}"

    # RDS database
    db_username = "mlflow"
    db_database = "mlflow"
    db_port = 3306

    # S3 bucket
    create_dedicated_bucket = var.artifact_bucket_id == null
    artifact_bucket_id      = local.create_dedicated_bucket ? aws_s3_bucket.artifact_store.0.id : var.artifact_bucket_id

    # App Runner
    app_port = 8080
    create_mlflow_password  = var.mlflow_password == null
    mlflow_password         = local.create_mlflow_password ? random_password.mlflow_password.result : var.mlflow_password

    tags = merge(
        {
            "Environment" = "${var.environment}"
        },
        var.tags
    )
}