##################################################################
# VPC
##################################################################

resource "aws_vpc" "vpc" {
  assign_generated_ipv6_cidr_block     = false
  cidr_block                           = "172.31.0.0/16"
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = false
  instance_tenancy                     = "default"
  tags = {
    Name = "bigbrain-vpc"
  }
}

##################################################################
# Internet Gateway (IGW)
##################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

##################################################################
# Subnets
##################################################################

locals {
  project_name   = "bigbrain"
  vpc_cidr_block = "172.31.32.0/20"
  public_subnets = {
    usw2a = { az = "us-west-2a", cidr = local.vpc_cidr_block, name = "${local.project_name}-subnet-1" }
    usw2b = { az = "us-west-2b", cidr = local.vpc_cidr_block, name = "${local.project_name}-subnet-2" }
    usw2c = { az = "us-west-2c", cidr = local.vpc_cidr_block, name = "${local.project_name}-subnet-3" }
    usw2d = { az = "us-west-2d", cidr = local.vpc_cidr_block, name = "${local.project_name}-subnet-4" }
  }
}

# Public Subnets
resource "aws_subnet" "subnet_public_usw2a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "172.31.32.0/20"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "bigbrain-subnet-1"
  }
}

resource "aws_subnet" "subnet_public_usw2b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "172.31.16.0/20"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "bigbrain-subnet-2"
  }
}

resource "aws_subnet" "subnet_public_usw2c" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "172.31.0.0/20"
  availability_zone       = "us-west-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "bigbrain-subnet-3"
  }
}

resource "aws_subnet" "subnet_public_usw2d" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "172.31.48.0/20"
  availability_zone       = "us-west-2d"
  map_public_ip_on_launch = true

  tags = {
    Name = "bigbrain-subnet-4"
  }
}

# Database Subnets (Private)
resource "aws_subnet" "subnet_rds_pvt_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "172.31.64.0/25"
  availability_zone       = "us-west-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "RDS-Pvt-subnet-1"
  }
}

resource "aws_subnet" "subnet_rds_pvt_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "172.31.64.128/25"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "RDS-Pvt-subnet-2"
  }
}

resource "aws_subnet" "subnet_rds_pvt_3" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "172.31.65.0/25"
  availability_zone       = "us-west-2d"
  map_public_ip_on_launch = false

  tags = {
    Name = "RDS-Pvt-subnet-3"
  }
}

resource "aws_subnet" "subnet_rds_pvt_4" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "172.31.65.128/25"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "RDS-Pvt-subnet-4"
  }
}

##################################################################
# Route Tables
##################################################################

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "rtb_rds_pvt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "RDS-Pvt-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "rta_subnet_rds_pvt_1" {
  subnet_id      = aws_subnet.subnet_rds_pvt_3.id
  route_table_id = aws_route_table.rtb_rds_pvt.id
}

resource "aws_route_table_association" "rta_subnet_rds_pvt_2" {
  subnet_id      = aws_subnet.subnet_rds_pvt_2.id
  route_table_id = aws_route_table.rtb_rds_pvt.id
}

resource "aws_route_table_association" "rta_subnet_rds_pvt_3" {
  subnet_id      = aws_subnet.subnet_rds_pvt_1.id
  route_table_id = aws_route_table.rtb_rds_pvt.id
}

resource "aws_route_table_association" "rta_subnet_rds_pvt_4" {
  subnet_id      = aws_subnet.subnet_rds_pvt_4.id
  route_table_id = aws_route_table.rtb_rds_pvt.id
}

##################################################################
# Security Groups
##################################################################

# ALB Security Group
resource "aws_security_group" "sg_alb" {
  name        = "bigbrain-alb"
  description = "Allow HTTP and HTTPS access from anywhere"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_https" {
  security_group_id = aws_security_group.sg_alb.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"

}

resource "aws_vpc_security_group_ingress_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.sg_alb.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = "0.0.0.0/0"

}

resource "aws_vpc_security_group_egress_rule" "alb_egress_all" {
  security_group_id = aws_security_group.sg_alb.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

}

# EC2 Security Group
resource "aws_security_group" "sg_ec2" {
  name        = "launch-wizard-1"
  description = "launch-wizard-1 created 2025-12-21T22:30:20.405Z"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_egress_rule" "ec2_egress_all" {
  security_group_id = aws_security_group.sg_ec2.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

}

resource "aws_vpc_security_group_ingress_rule" "ec2_ingress_app_from_alb" {
  security_group_id = aws_security_group.sg_ec2.id

  ip_protocol                  = "tcp"
  from_port                    = 5005
  to_port                      = 5005
  referenced_security_group_id = aws_security_group.sg_alb.id
  description                  = "Rule to allow connections over port 5005 from ALB security group"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ingress_ssh" {
  security_group_id = aws_security_group.sg_ec2.id

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = "0.0.0.0/0"
  description = "Rule to allow connections using SSH from my computer"
}

# RDS Security Group
resource "aws_security_group" "sg_rds" {
  name        = "rds-ec2-1"
  description = "Security group attached to bigbrain-database to allow EC2 instances with specific security groups attached to connect to the database. Modification could lead to connection loss."
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_ingress_postgres_from_ec2_rds" {
  security_group_id = aws_security_group.sg_rds.id

  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.sg_ec2_rds.id
  description                  = "Rule to allow connections from EC2 instances with sg-0daf2a16e2fabe299 attached"
}

# EC2-to-RDS Security Group
resource "aws_security_group" "sg_ec2_rds" {
  name        = "ec2-rds-1"
  description = "Security group attached to instances to securely connect to bigbrain-database. Modification could lead to connection loss."
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_egress_rule" "ec2_rds_egress_postgres_to_rds" {
  security_group_id = aws_security_group.sg_ec2_rds.id

  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.sg_rds.id
  description                  = "Rule to allow connections to bigbrain-database from any instances this security group is attached to"
}
