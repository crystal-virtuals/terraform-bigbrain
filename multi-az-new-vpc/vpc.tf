################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = "vpc-${local.name}"
  cidr = var.vpc_cidr_block

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr_block, 8, k)]     # Creates /24 subnets (10.0.0.0/24, 10.0.1.0/24, etc.)
  private_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr_block, 8, k + 3)] # Creates /24 subnets
  database_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr_block, 8, k + 6)] # Creates /24 subnets

  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  create_database_subnet_group = true

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = local.tags
}
