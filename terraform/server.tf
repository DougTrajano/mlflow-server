resource "random_password" "mlflow_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_apprunner_service" "mlflow_server" {
  service_name = "${local.name}"

  source_configuration {
    auto_deployments_enabled = false

    image_repository {
      image_identifier      = "public.ecr.aws/t9j8s4z8/mlflow:${var.mlflow_version}"
      image_repository_type = "ECR_PUBLIC"

      image_configuration {
        port = local.app_port
        runtime_environment_variables = {
          "MLFLOW_ARTIFACT_URI" = "s3://${aws_s3_bucket.mlflow_artifact_store.0.id}"
          "MLFLOW_DB_DIALECT" = "postgresql"
          "MLFLOW_DB_USERNAME" = "${aws_rds_cluster.mlflow_backend_store.master_username}"
          "MLFLOW_DB_PASSWORD" = "${random_password.mlflow_backend_store.result}"
          "MLFLOW_DB_HOST" = "${aws_rds_cluster.mlflow_backend_store.endpoint}"
          "MLFLOW_DB_PORT" = "${aws_rds_cluster.mlflow_backend_store.port}"
          "MLFLOW_DB_DATABASE" = "${aws_rds_cluster.mlflow_backend_store.database_name}"
          "MLFLOW_TRACKING_USERNAME" = var.mlflow_username
          "MLFLOW_TRACKING_PASSWORD" = local.mlflow_password
          "MLFLOW_SQLALCHEMYSTORE_POOL_CLASS" = "NullPool"
          }
        }    
      }
  }

  instance_configuration {
    cpu = var.service_cpu
    memory = var.service_memory
    instance_role_arn = aws_iam_role.mlflow_iam_role.arn
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.connector.arn
    }
  }

  health_check_configuration {
    healthy_threshold   = 1
    unhealthy_threshold = 5
    interval            = 20
    timeout             = 20
    path                = "/health"
    protocol            = "HTTP"
  }

  tags = merge(
    {
        Name = "${local.name}"
    },
    local.tags
  )
}

resource "aws_security_group" "mlflow_server_sg" {
  count       = local.create_dedicated_vpc ? 1 : 0
  name        = "${var.name}-server-sg"
  description = "Allow access to ${local.name}-rds from VPC Connector."
  vpc_id      = local.vpc_id

  ingress {
    description = "Access to ${local.name}-rds from VPC Connector."
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.name}-server-sg"
  }
}

resource "aws_apprunner_vpc_connector" "connector" {
  vpc_connector_name = "${local.name}-connector"
  subnets            = local.db_subnet_ids
  security_groups    = local.create_dedicated_vpc ? [aws_security_group.mlflow_server_sg.0.id] : var.vpc_security_group_ids
}
