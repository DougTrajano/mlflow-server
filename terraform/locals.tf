data "aws_availability_zones" "available" {
  state = "available"
}

locals {
    # General
    name = "${var.name}-${var.environment}"

    availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

    # RDS database
    db_username = "mlflow"
    db_database = "mlflow"
    db_port = 5432
    db_subnet_ids = local.create_dedicated_vpc ? aws_subnet.mlflow_public_subnet.*.id : var.db_subnet_ids

    # VPC and subnets
    create_dedicated_vpc    = var.vpc_id == null
    vpc_id                  = local.create_dedicated_vpc ? aws_vpc.mlflow_vpc.0.id : var.vpc_id

    # S3 bucket
    create_dedicated_bucket = var.artifact_bucket_id == null
    artifact_bucket_id      = local.create_dedicated_bucket ? module.s3.artifact_bucket_id : var.artifact_bucket_id

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