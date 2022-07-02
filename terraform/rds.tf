resource "random_password" "mlflow_backend_store" {
  length  = 16
  special = true

  # Added this because random password was generating a password that had chars that
  # aurora didnt allow. With the lifecycle this shouldnt impact existing passwords that
  # happened to generate ok.
  override_special = "_+=()"
  lifecycle {
    ignore_changes = [override_special]
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "${local.name}-rds-subnet-group"
  subnet_ids = local.db_subnet_ids
}

resource "aws_rds_cluster" "mlflow_backend_store" {
  cluster_identifier        = "${local.name}-rds"
  engine                    = "aurora-postgresql"
  engine_mode               = "serverless"
  port                      = local.db_port
  db_subnet_group_name      = aws_db_subnet_group.rds.name
  vpc_security_group_ids    = [aws_security_group.mlflow_server_sg.0.id]
  availability_zones        = local.availability_zones
  database_name             = local.db_database
  master_username           = local.db_username
  master_password           = random_password.mlflow_backend_store.result
  backup_retention_period   = 5
  preferred_backup_window   = "04:00-06:00"
  final_snapshot_identifier = "mlflow-db-backup"
  skip_final_snapshot       = var.db_skip_final_snapshot
  deletion_protection       = var.db_deletion_protection
  apply_immediately         = true

  scaling_configuration {
    min_capacity             = var.db_min_capacity
    max_capacity             = var.db_max_capacity
    auto_pause               = var.db_auto_pause
    seconds_until_auto_pause = var.db_auto_pause_seconds
  }

  tags = merge(
    {
      Name = "${local.name}-rds"
    },
    local.tags
  )
}