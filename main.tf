# Configure the AWS Provider
locals {
  name = "${var.project_name}-${var.environment}"

  required_tags = {
    project     = var.project_name,
    environment = var.environment
  }

  tags = merge(var.resource_tags, local.required_tags)

  # Split the network across 3 availability zones
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

provider "aws" {
  region = var.aws_region
}

##################################################################
# Data
##################################################################

# Data source to get current AWS account information
data "aws_caller_identity" "current" {}

# Data source to get current AWS region
data "aws_region" "current" {}

# Data source to fetch available list of availability zones
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

##################################################################
# IAM
##################################################################
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role-${local.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.project_name}-instance_profile"
  role = aws_iam_role.ec2_role.name
}

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

##################################################################
# Application Load Balancer
##################################################################

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.4.0"

  name               = "alb-${local.name}"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_security_group.security_group_id]

  # Prevent deletion of the ALB (defaults to true)
  enable_deletion_protection = false
  create_security_group      = false

  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.acm_certificate_arn

      forward = {
        # The value of the `target_group_key` is the key used in the `target_groups` map below
        target_group_key = "instance-target"
      }
    }
  }

  target_groups = {
    # This key name is used by the listener/listener rules to know which target to forward traffic to
    instance-target = {
      name_prefix = "app"
      protocol    = "HTTP"
      port        = var.app_port
      target_type = "instance"
      target_id   = aws_instance.app.id
      health_check = {
        enabled             = true
        protocol            = "HTTP"
        path                = "/health"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  }

  tags = local.tags
}

##################################################################
# RDS
##################################################################

# Generate a random password for the database.
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]{}<>:?" # Remove $ to avoid expansion issues in user-data script
}

# Use the provided password or the generated one
locals {
  database_password = coalesce(var.db_password, random_password.db_password.result)
}

module "postgres" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.0.1"

  # The name of the RDS instance
  identifier = "postgres-${local.name}"

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine                   = "postgres"
  engine_version           = "17"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  family                   = "postgres17" # DB parameter group
  major_engine_version     = "17"         # DB option group
  instance_class           = "db.t4g.micro"

  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  port     = 5432

  password_wo                 = local.database_password
  password_wo_version         = 1
  manage_master_user_password = false # Set to false to disable Secrets Manager integration

  multi_az               = false
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.postgres_security_group.security_group_id]

  backup_retention_period = 1
  skip_final_snapshot     = true  # Set to true to skip final snapshot on deletion (not recommended for production)
  deletion_protection     = false # Database Deletion Protection: Set to false to allow deletion of the RDS instance

  publicly_accessible = false

  tags = local.tags
}

##################################################################
# EC2
##################################################################

# Data source to fetch the latest Amazon Linux 2023 (AL2023 x86_64) AMI ID
data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"] # or ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create an EC2 instance
resource "aws_instance" "app" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id # Fetching the latest AL2023 AMI ID from the data source
  instance_type = var.ec2_instance_type

  subnet_id              = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids = [module.app_security_group.security_group_id]

  # IAM role for EC2 instance
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  associate_public_ip_address = true

  # Provisioning script to install node, clone repo and run the backend as a service.
  user_data = templatefile("${path.module}/user-data.tftpl", {
    project_name         = var.project_name
    environment          = var.environment
    app_repository       = var.app_repository
    app_port             = tostring(var.app_port)
    app_root             = var.app_root
    db_connection_string = "postgresql://${var.db_username}:${local.database_password}@${module.postgres.db_instance_address}:${module.postgres.db_instance_port}/${var.db_name}"
  })
  user_data_replace_on_change = true

  tags = merge({ Name = "${local.name}-app" }, local.tags)
}

##################################################################
# Amplify
##################################################################

resource "aws_amplify_app" "frontend" {
  name       = "${var.project_name}-frontend"
  repository = var.amplify_repository

  # GitHub personal access token
  access_token = var.github_access_token

  platform = "WEB"

  # The default rewrites and redirects added by the Amplify Console.
  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }

  environment_variables = var.amplify_app_environment_variables

  tags = local.tags
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = "main"

  framework = "React"
  # stage     = "PRODUCTION"

  environment_variables = var.amplify_branch_environment_variables
}

resource "aws_amplify_webhook" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = aws_amplify_branch.main.branch_name
  description = "Trigger Amplify build from Terraform"
}

resource "null_resource" "trigger_amplify_deploy" {
  triggers = {
    # Re-trigger if the webhook URL changes, or if you bump this value manually
    webhook_url = aws_amplify_webhook.main.url
    trigger_ver = "1"
  }

  provisioner "local-exec" {
    command = "curl -X POST '${aws_amplify_webhook.main.url}'"
  }

  depends_on = [aws_amplify_branch.main]
}
