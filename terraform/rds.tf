resource "random_password" "backend_store" {
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

resource "aws_db_instance" "backend_store" {
  identifier                = "${local.name}-db"
  allocated_storage         = 5
  max_allocated_storage     = 100
  engine                    = "mysql"
  engine_version            = "8.0.23"
  instance_class            = var.db_instance_class
  name                      = local.db_database
  username                  = local.db_username
  password                  = "${random_password.backend_store.result}"
  port                      = local.db_port
  final_snapshot_identifier = "mlflow-db-backup"
  skip_final_snapshot       = var.db_skip_final_snapshot
  backup_retention_period   = 1
  backup_window             = "04:00-06:00"
  apply_immediately         = true
  publicly_accessible       = true

  tags = merge(
    {
      Name = "${local.name}-rds"
    },
    local.tags
  )
}

###
# The following resources needs a new feature in the app runner that allows access to resources in a VPC
# It is currently in AWS App Runner roadmap.
###

# data "aws_availability_zones" "available" {
#   state = "available"
# }

# resource "aws_rds_cluster" "backend_store" {
#   cluster_identifier        = "${local.name}-rds"
#   engine                    = "aurora-mysql"
#   engine_version            = "5.7.mysql_aurora.2.10.0"
#   engine_mode               = "serverless"
#   port                      = local.db_port
#   # db_subnet_group_name    = aws_db_subnet_group.rds.name
#   # vpc_security_group_ids  = [aws_security_group.rds.id]
#   availability_zones        = slice(data.aws_availability_zones.available.names, 0, 2)
#   database_name             = local.db_database
#   master_username           = local.db_username
#   master_password           = random_password.backend_store.result
#   backup_retention_period   = 5
#   preferred_backup_window   = "04:00-06:00"
#   final_snapshot_identifier = "mlflow-db-backup"
#   skip_final_snapshot       = var.db_skip_final_snapshot
#   apply_immediately         = true

#   scaling_configuration {
#     min_capacity             = var.db_min_capacity
#     max_capacity             = var.db_max_capacity
#     auto_pause               = var.db_auto_pause
#     seconds_until_auto_pause = var.db_auto_pause_seconds
#     timeout_action           = "ForceApplyCapacityChange"
#   }

#   tags = merge(
#     {
#       Name = "${local.name}-rds"
#     },
#     local.tags
#   )
# }