##################################################################
# VPC
##################################################################

import {
  to = aws_vpc.vpc
  id = "vpc-06cd575bfc9436ba0"
}

##################################################################
# Internet Gateway (IGW)
##################################################################

import {
  to = aws_internet_gateway.igw
  id = "igw-03ef30eb65a2fe4c6"
}

##################################################################
# Subnets
##################################################################

# Public Subnets
import {
  to = aws_subnet.subnet_public_usw2a
  id = "subnet-01e4fc722c534da45"
}

import {
  to = aws_subnet.subnet_public_usw2b
  id = "subnet-052b25e953fb4875f"
}

import {
  to = aws_subnet.subnet_public_usw2c
  id = "subnet-0e52bd54b3ff379d5"
}

import {
  to = aws_subnet.subnet_public_usw2d
  id = "subnet-09773503e1cfc7b28"
}

# RDS private subnets
import {
  to = aws_subnet.subnet_rds_pvt_1
  id = "subnet-0a287b6d8d311e610"
}

import {
  to = aws_subnet.subnet_rds_pvt_2
  id = "subnet-0f82afc2bc8c04494"
}

import {
  to = aws_subnet.subnet_rds_pvt_3
  id = "subnet-0c6c222f40c64b49c"
}

import {
  to = aws_subnet.subnet_rds_pvt_4
  id = "subnet-03a3a0fb8275424f0"
}

##################################################################
# Route Tables
##################################################################

# Main public route table (0.0.0.0/0 -> IGW)
import {
  to = aws_route_table.rtb_public
  id = "rtb-0db8aadf00870cf6e"
}

# RDS private route table (local-only, named RDS-Pvt-rt)
import {
  to = aws_route_table.rtb_rds_pvt
  id = "rtb-0ce13a83f9b538c4f"
}

##################################################################
# Route Table Associations
##################################################################

# RDS private route table subnet associations
import {
  to = aws_route_table_association.rta_subnet_rds_pvt_1
  id = "subnet-0c6c222f40c64b49c/rtb-0ce13a83f9b538c4f"
}

import {
  to = aws_route_table_association.rta_subnet_rds_pvt_2
  id = "subnet-0f82afc2bc8c04494/rtb-0ce13a83f9b538c4f"
}

import {
  to = aws_route_table_association.rta_subnet_rds_pvt_3
  id = "subnet-0a287b6d8d311e610/rtb-0ce13a83f9b538c4f"
}

import {
  to = aws_route_table_association.rta_subnet_rds_pvt_4
  id = "subnet-03a3a0fb8275424f0/rtb-0ce13a83f9b538c4f"
}

##################################################################
# Security Groups
##################################################################

# ALB security group
import {
  to = aws_security_group.sg_alb
  id = "sg-0be702d87e9dcbe1a"
}

import {
  to = aws_vpc_security_group_ingress_rule.alb_ingress_https
  id = "sgr-02431bc15af89b6ac"
}

import {
  to = aws_vpc_security_group_ingress_rule.alb_ingress_http
  id = "sgr-077068f3283357c58"
}

import {
  to = aws_vpc_security_group_egress_rule.alb_egress_all
  id = "sgr-076b70c05eb6ad694"
}

# EC2 security groups
import {
  to = aws_security_group.sg_ec2
  id = "sg-02a920375c764912e"
}

import {
  to = aws_vpc_security_group_egress_rule.ec2_egress_all
  id = "sgr-0a45afa2ad431d487"
}

import {
  to = aws_vpc_security_group_ingress_rule.ec2_ingress_app_from_alb
  id = "sgr-05a3a98aab4fa4444"
}

import {
  to = aws_vpc_security_group_ingress_rule.ec2_ingress_ssh
  id = "sgr-03191148ad1711c6b"
}

# RDS security group (rds-ec2-1)
import {
  to = aws_security_group.sg_rds
  id = "sg-03a3a8df278442583"
}

import {
  to = aws_vpc_security_group_ingress_rule.rds_ingress_postgres_from_ec2_rds
  id = "sgr-0a66a5fd4643dee51"
}

# EC2 to RDS security group (ec2-rds-1)
import {
  to = aws_security_group.sg_ec2_rds
  id = "sg-0daf2a16e2fabe299"
}

import {
  to = aws_vpc_security_group_egress_rule.ec2_rds_egress_postgres_to_rds
  id = "sgr-032734de227ab8fd9"
}

###############################################################################
# ALB (Load Balancer)
###############################################################################

# ALB
import {
  to = aws_lb.app_alb
  id = "arn:aws:elasticloadbalancing:us-west-2:929593185725:loadbalancer/app/test/ee2fc8789bb7e846"
}

# Target Group
import {
  to = aws_lb_target_group.app_tg
  id = "arn:aws:elasticloadbalancing:us-west-2:929593185725:targetgroup/bigbrain-api-http-5005/a4de165c6da561d8"
}

# Listeners
import {
  to = aws_lb_listener.https_443
  id = "arn:aws:elasticloadbalancing:us-west-2:929593185725:listener/app/test/ee2fc8789bb7e846/84e41a051a30bb97"
}

import {
  to = aws_lb_listener.http_80
  id = "arn:aws:elasticloadbalancing:us-west-2:929593185725:listener/app/test/ee2fc8789bb7e846/93913f5b2f081560"
}

###############################################################################
# EC2
###############################################################################

import {
  to = aws_instance.app_server
  id = "i-00f172cbc2be7fc07"
}

###############################################################################
# RDS
###############################################################################

# RDS subnet group
import {
  to = aws_db_subnet_group.database_subnet_group
  id = "rds-ec2-db-subnet-group-1"
}

# RDS instance
import {
  to = aws_db_instance.database
  id = "bigbrain-database"
}

###############################################################################
# Amplify
###############################################################################

# Amplify App
import {
  to = aws_amplify_app.frontend
  id = "d2mihgx6p61hm0"
}

# Amplify Branch (production branch is "main")
import {
  to = aws_amplify_branch.main
  id = "d2mihgx6p61hm0/main"
}
