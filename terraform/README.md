# Terraform stack

> Terraform v1.0.1 on linux_amd64

This directory contains the Terraform configuration for the MLflow Server stack.

## Terraform configuration

The Terraform configuration is based on the [Terraform documentation](https://www.terraform.io/docs/index.html) and the [AWS provider](https://www.terraform.io/docs/providers/aws/index.html).

The Terraform configuration is split into two files:

- `iam.tf`: AWS IAM configuration.
- `locals.tf`: The Terraform locals file.
- `providers.tf`: The Terraform providers file.
- `rds.tf`: AWS RDS database configuration (Backend store).
- `s3.tf`: AWS S3 configuration (Artifact store).
- `server.tf`: AWS App Runner configuration (MLflow Server).
- `variables.tf`: The Terraform variables file.

## Terraform variables

The Terraform variables file contains the following variables:

- `name` - (Optional) The name of the stack. Defaults to `mlflow`.
- `environment` - (Optional) The environment of the stack. Defaults to `dev`.
- `region` - (Optional) The AWS region. Defaults to `us-east-1`.
- `tags` - (Optional) The tags to apply to the stack. Defaults to `{}`.
- `service_cpu` - (Optional) The number of CPU cores to allocate to the MLflow Server. Defaults to `1024`.
- `service_memory` - (Optional) The amount of memory to allocate to the MLflow Server. Defaults to `2048`.
- `mlflow_username` - (Optional) The username to use for the MLflow Server. Defaults to `mlflow`.
- `mlflow_password` - (Optional) The password to use for the MLflow Server. Defaults to `mlflow`.
- `artifact_bucket_id` - (Optional) The S3 bucket ID to use for the MLflow Server artifact store. If specified, MLflow will use this bucket to store artifacts. Otherwise, this module will create a dedicated bucket.
- `db_skip_final_snapshot` - (Optional) Whether to skip creating a final DB snapshot. Default is `false`.
- `db_instance_class` - (Optional) The DB instance class to use. Defaults to `db.t2.micro`.

## Terraform providers

The Terraform providers file contains the following providers:

- `aws`: The AWS provider.

## Terraform locals

The Terraform locals file contains the following locals:

- `name` - The name of the stack. (e.g. `{name}-{environment}`)
- `db_username` - The username to use for the MLflow Server database.
- `db_password` - The password to use for the MLflow Server database.
- `db_port` - The port to use for the MLflow Server database.
- `create_dedicated_bucket` - Whether to create a dedicated S3 bucket for the MLflow Server artifact store.
- `artifact_bucket_id` - The S3 bucket ID to use for the MLflow Server artifact store.
- `app_port` - The port to use for the MLflow Server.
- `tags` - The tags to apply to the stack (Add `Name` and `Environment` tags).

## Terraform outputs

The Terraform outputs file contains the following outputs:

- `artifact_bucket_id` - The S3 bucket ID to use for the MLflow Server artifact store.
- `service_url` - The URL to the MLflow Server.
- `mlflow_username` - The username to use for the MLflow Server.
- `mlflow_password` - The password to use for the MLflow Server.
- `status` - The status of the MLflow Server service.