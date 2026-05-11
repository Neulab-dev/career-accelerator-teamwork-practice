module "vpc" {
  # commit hash of version 6.6.1
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=7a28ce8ec6a17a8ca52710e47763f3a52c155110"

  name = "${var.prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Allow internal traffic from private subnets to DynamoDB
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.eu-central-1.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}