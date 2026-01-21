################################################################################
# Security Groups
################################################################################

module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "alb-sg-${local.name}"
  description = "Security group for ${local.name} application load balancer with HTTP and HTTPS ports publicly open, and allow egress access within current VPC"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP web traffic"
    },
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS web traffic"
    }
  ]

  # Outbound only to VPC
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "ALB access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]

  tags = local.tags
}

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "app-sg-${local.name}"
  description = "Security group for app-server to allow traffic from ALB on port ${var.app_port}"
  vpc_id      = module.vpc.vpc_id

  # SSH access
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  # ALB to EC2
  ingress_with_source_security_group_id = [
    {
      from_port                = var.app_port
      to_port                  = var.app_port
      protocol                 = "tcp"
      description              = "Rule to allow connections from instances with ${module.alb_security_group.security_group_id} attached on port ${var.app_port}"
      source_security_group_id = module.alb_security_group.security_group_id
    }
  ]

  egress_rules = ["all-all"]

  tags = local.tags
}

module "postgres_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "postgresql-sg-${local.name}"
  description = "Allow PostgreSQL inbound traffic"
  vpc_id      = module.vpc.vpc_id

  # Inbound rules
  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "PostgreSQL access from EC2 instances with ${module.app_security_group.security_group_id} attached"
      source_security_group_id = module.app_security_group.security_group_id
    },
  ]

  tags = local.tags
}
