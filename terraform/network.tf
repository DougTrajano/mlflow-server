resource "aws_vpc" "mlflow_vpc" {
  count                = local.create_dedicated_vpc ? 1 : 0
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name}-vpc"
  }
}

resource "aws_subnet" "mlflow_public_subnet" {
  count                   = local.create_dedicated_vpc ? length(local.availability_zones) : 0
  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.${10+count.index}.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"

  tags = {
    Name = "${local.name}-public-subnet"
  }
}

resource "aws_internet_gateway" "mlflow_gateway" {
  count  = local.create_dedicated_vpc ? 1 : 0
  vpc_id = local.vpc_id

  tags = {
    Name = "${local.name}-igw"
  }
}

resource "aws_route_table" "mlflow_crt" {
  count  = local.create_dedicated_vpc ? 1 : 0
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mlflow_gateway.0.id
  }

  tags = {
    Name = "${local.name}-crt"
  }
}

resource "aws_route_table_association" "mlflow_crt_association" {
  count          = local.create_dedicated_vpc ? 1 : 0
  subnet_id      = aws_subnet.mlflow_public_subnet.0.id
  route_table_id = aws_route_table.mlflow_crt.0.id
}
