##################################################################
# VPC
##################################################################

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

##################################################################
# Internet Gateway (IGW)
##################################################################

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

##################################################################
# Subnets
##################################################################

output "default_public_subnet_for_app" {
  value = aws_subnet.subnet_public_usw2c.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.subnet_public_usw2a.id,
    aws_subnet.subnet_public_usw2b.id,
    aws_subnet.subnet_public_usw2c.id,
    aws_subnet.subnet_public_usw2d.id,
  ]
}

output "rds_private_subnet_ids" {
  value = [
    aws_subnet.subnet_rds_pvt_1.id,
    aws_subnet.subnet_rds_pvt_2.id,
    aws_subnet.subnet_rds_pvt_3.id,
    aws_subnet.subnet_rds_pvt_4.id,
  ]
}

##################################################################
# Route Tables
##################################################################

output "public_route_table_id" {
  value = aws_route_table.rtb_public.id
}

output "rds_route_table_id" {
  value = aws_route_table.rtb_rds_pvt.id
}

##################################################################
# Security Groups
##################################################################

output "sg_alb_id" {
  value = aws_security_group.sg_alb.id
}

output "sg_ec2_id" {
  value = aws_security_group.sg_ec2.id
}

output "sg_rds_id" {
  value = aws_security_group.sg_rds.id
}

output "sg_ec2_rds_id" {
  value = aws_security_group.sg_ec2_rds.id
}

##################################################################
# ALB
##################################################################



##################################################################
# EC2
##################################################################


##################################################################
# RDS
##################################################################

output "rds_identifier" {
  value = aws_db_instance.database.identifier
}

output "rds_endpoint" {
  description = "DNS endpoint clients use to connect (no port)."
  value       = aws_db_instance.database.address
}

output "rds_port" {
  value = aws_db_instance.database.port
}

output "rds_db_name" {
  description = "May be null if the DB was created without an initial database name."
  value       = aws_db_instance.database.db_name
}

output "rds_engine" {
  value = aws_db_instance.database.engine
}

output "rds_engine_version" {
  value = aws_db_instance.database.engine_version
}

output "rds_security_group_id" {
  value = aws_security_group.sg_rds.id
}

output "rds_subnet_group_name" {
  value = aws_db_subnet_group.database_subnet_group.name
}

output "rds_subnet_ids" {
  value = aws_db_subnet_group.database_subnet_group.subnet_ids
}

output "rds_kms_key_id" {
  value = aws_db_instance.database.kms_key_id
}

output "rds_arn" {
  value = aws_db_instance.database.arn
}

##################################################################
# Amplify
##################################################################

output "amplify_app_id" {
  value = aws_amplify_app.frontend.id
}

output "amplify_app_arn" {
  value = aws_amplify_app.frontend.arn
}

output "amplify_repo_url" {
  value = aws_amplify_app.frontend.repository
}

output "amplify_branch_name" {
  value = aws_amplify_branch.main.branch_name
}
