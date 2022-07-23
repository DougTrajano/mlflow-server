# [MLflow](https://www.mlflow.org/) with basic auth

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/DougTrajano/mlflow-server/tree/main)

This project deploys an MLflow Tracking Server with basic auth (username and password).

We also provide a [Terraform](https://www.terraform.io/) configuration in the [terraform](terraform) directory that creates the required resources in AWS.  It uses the [AWS App Runner](https://aws.amazon.com/apprunner/) (a low-cost solution to run containers on AWS) to run the server.

## Architecture

![](docs/images/architecture_mlflow.png)

<details><summary>Amazon ECR</summary>
<p>

[Amazon Elastic Container Registry (ECR)](https://aws.amazon.com/ecr/) is a fully managed container registry that makes it easy to store, manage, share, and deploy your container images and artifacts anywhere.

</p>
</details>

<details><summary>App Runner</summary>
<p>

[AWS App Runner](https://aws.amazon.com/apprunner/) is a fully managed service that makes it easy for developers to quickly deploy containerized web applications and APIs, at scale and with no prior infrastructure experience required. Start with your source code or a container image.

</p>
</details>

<details><summary>Amazon S3</summary>
<p>

[Amazon Simple Storage Service (Amazon S3)](https://aws.amazon.com/s3/) is an object storage service that offers industry-leading scalability, data availability, security, and performance.

</p>
</details>

<details><summary>Amazon Aurora Serverless</summary>
<p>

[Amazon Aurora Serverless](https://aws.amazon.com/rds/aurora/serverless/) is an on-demand, autoscaling configuration for Amazon Aurora. It automatically starts up, shuts down, and scales capacity up or down based on your application's needs. You can run your database on AWS without managing database capacity.

</p>
</details>

## Environment Variables

The environment variables below are required to deploy this project.

| Variable | Description | Default |
| - | - | - |
| PORT | Port for the MLflow server | `80` |
| MLFLOW_ARTIFACT_URI | S3 Bucket URI for MLflow's artifact store | `"./mlruns"`
| MLFLOW_BACKEND_URI | [SQLAlchemy database uri](https://docs.sqlalchemy.org/en/latest/core/engines.html#database-urls) (if provided, the other variables `MLFLOW_DB_*` are ignored) | |
| MLFLOW_DB_DIALECT | Database dialect (e.g. postgresql, mysql+pymysql, sqlite) | `"mysql+pymysql"` |
| MLFLOW_DB_USERNAME | Backend store username | `"mlflow"` |
| MLFLOW_DB_PASSWORD | Backend store password | `"mlflow"` |
| MLFLOW_DB_HOST | Backend store host | |
| MLFLOW_DB_PORT | Backend store port | `3306` |
| MLFLOW_DB_DATABASE | Backend store database | `"mlflow"` |
| MLFLOW_TRACKING_USERNAME | Username for MLflow UI and API | `"mlflow"` |
| MLFLOW_TRACKING_PASSWORD | Password for MLflow UI and API | `"mlflow"` |

## Using your deployed MLflow

You can access the MLflow UI in your App Runner URL: https://XXXXXXXXX.aws-region.awsapprunner.com/

![](docs/images/mlflow_ui.png)

Also, you can track your experiments using MLflow API.

```python
import os
import mlflow

os.environ["MLFLOW_TRACKING_URI"] = "https://XXXXXXXXX.aws-region.awsapprunner.com/"
os.environ["MLFLOW_EXPERIMENT_NAME"] = "amazing-experiment"
os.environ["MLFLOW_TRACKING_USERNAME"] = "user"
os.environ["MLFLOW_TRACKING_PASSWORD"] = "pass"

# AWS AK/SK are required to upload artifacts to S3 Bucket
os.environ["AWS_ACCESS_KEY_ID"] = "AWS_ACCESS_KEY"
os.environ["AWS_SECRET_ACCESS_KEY"] = "AWS_SECRET_KEY"

SEED = 1993

mlflow.start_run()
mlflow.log_param("seed", SEED)
mlflow.end_run()
```

## How to deploy MLflow with auth

In this section, we'll walk through deploying this MLflow docker image with basic authentication.

This project provides a terraform stack that can be easily used to deploy the MLflow server with basic authentication.

> **NOTE**: This project is not intended to be used for production deployments. It is intended to be used for testing and development.

### Prerequisites

You'll need to have the following installed:

- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform CLI](https://www.terraform.io/downloads.html)

### Deploying MLflow

To deploy MLflow, you'll need to:

1. [Create an AWS account](https://aws.amazon.com/free/) if you don't already have one.

2. Configure AWS CLI to use your AWS account.

3. Clone this repository.

```bash
git clone https://github.com/DougTrajano/mlflow-server.git
```

4. Open `mlflow-server/terraform` folder.

```bash
cd mlflow-server/terraform
```

5. Run the following command to create all the required resources:

```bash
terraform init
terraform apply -var mlflow_username="YOUR-USERNAME" -var mlflow_password="YOUR-PASSWORD"
```

See a full list of variables that can be used in [terraform/variables.tf](terraform/variables.tf).

6. Type "yes" when prompted to continue.

```log
Plan: 21 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + artifact_bucket_id = (known after apply)
  + mlflow_password    = (sensitive value)
  + mlflow_username    = "doug"
  + service_url        = (known after apply)
  + status             = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

This will create the following resources:

- An [S3 bucket](https://aws.amazon.com/s3/) used to store MLflow artifacts.
- An [IAM role and policy](https://aws.amazon.com/iam/) that allow MLflow to access the S3 bucket.
- An [Aurora RDS Serverless](https://aws.amazon.com/rds/aurora/serverless/) database (PostgreSQL) used to store MLflow data.
- An [App Runner](https://aws.amazon.com/apprunner/) that will run the MLflow Tracking Server.
- (Optional) A set of network resources such as [VPC](https://aws.amazon.com/vpc/), [Subnet](https://aws.amazon.com/ec2/subnets/), and [Security group](https://aws.amazon.com/ec2/security-groups/).

## References

- [Managing your machine learning lifecycle with MLflow and Amazon SageMaker | AWS Machine Learning Blog](https://aws.amazon.com/pt/blogs/machine-learning/managing-your-machine-learning-lifecycle-with-mlflow-and-amazon-sagemaker/)
- [Introducing AWS App Runner](https://aws.amazon.com/pt/blogs/containers/introducing-aws-app-runner/)
- [MLflow Documentation](https://www.mlflow.org/docs/latest/index.html) (current version: 1.25.1)
- [soundsensing/mlflow-easyauth: Deploy MLflow with HTTP basic authentication using Docker](https://github.com/soundsensing/mlflow-easyauth)
