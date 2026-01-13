output "aws_region" {
  description = "AWS region"
  value       = data.aws_region.current.region
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "ID of project VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "ARN of the vpc."
  value       = module.vpc.vpc_arn
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

################################################################################
# EC2
################################################################################

output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.app.public_dns
}

################################################################################
# Load Balancer
################################################################################

output "alb_id" {
  description = "The ID and ARN of the load balancer we created"
  value       = module.alb.id
}

output "alb_arn" {
  description = "The ID and ARN of the load balancer we created"
  value       = module.alb.arn
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "The zone_id of the load balancer to assist with creating DNS records"
  value       = module.alb.zone_id
}

################################################################################
# Listener(s)
################################################################################

output "alb_listeners" {
  description = "Map of listeners created and their attributes"
  value       = module.alb.listeners
  sensitive   = true
}

output "alb_listener_rules" {
  description = "Map of listeners rules created and their attributes"
  value       = module.alb.listener_rules
  sensitive   = true
}

################################################################################
# Target Group(s)
################################################################################

output "alb_target_groups" {
  description = "Map of target groups created and their attributes"
  value       = module.alb.target_groups
}

################################################################################
# Security Group
################################################################################

output "alb_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = module.alb.security_group_arn
}

output "alb_security_group_id" {
  description = "ID of the security group"
  value       = module.alb.security_group_id
}

################################################################################
# Route53 Record(s)
################################################################################

output "route53_records" {
  description = "The Route53 records created and attached to the load balancer"
  value       = module.alb.route53_records
}

################################################################################
# RDS
###################Topics#############################################################

output "db_connection_string" {
  description = "Database connection string"
  value       = "postgresql://${var.db_username}:${var.db_password}@${module.postgres.endpoint}/${var.db_name}"
  sensitive   = true
}

################################################################################
# Amplify
################################################################################

output "amplify_app_name" {
  description = "Amplify App name"
  value       = aws_amplify_app.frontend.name
}

output "amplify_app_arn" {
  description = "Amplify App ARN "
  value       = aws_amplify_app.frontend.arn
}

output "amplify_app_default_domain" {
  description = "Amplify App domain (non-custom)"
  value       = aws_amplify_app.frontend.default_domain
}



