variable "aws_region" {
  description = "AWS region to deploy resources in. Defaults to the Region set in the provider configuration"
  type        = string
  default     = "us-west-2"
}

# Globals
variable "user_name" {
  description = "The user creating this infrastructure"
  default     = "ec2-user"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "project"
}

variable "environment" {
  description = "Name of the environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# VPC
################################################################################
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for VPC"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Enable a VPN gateway in your VPC."
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "public_subnet_count" {
  description = "Number of public subnets."
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets."
  type        = number
  default     = 2
}

variable "public_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets."
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24",
    "10.0.7.0/24",
    "10.0.8.0/24",
  ]
}

variable "private_subnet_cidr_blocks" {
  description = "Available cidr blocks for private subnets."
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24",
    "10.0.105.0/24",
    "10.0.106.0/24",
    "10.0.107.0/24",
    "10.0.108.0/24",
  ]
}

################################################################################
# EC2
################################################################################
variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

################################################################################
# ACM
################################################################################
variable "use_existing_route53_zone" {
  description = "Use existing (via data source) or create new zone (will fail validation, if zone is not reachable)"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "The domain name for which the certificate should be issued"
  type        = string
}

variable "acm_certificate_arn" {
  type        = string
  description = "Existing ACM certificate ARN for the domain"
}

################################################################################
# RDS
################################################################################
variable "db_name" {
  description = "The DB name to create. If omitted, no database is created initially"
  type        = string
  default     = "MyDatabase"

  # DBName must begin with a letter and contain only alphanumeric characters
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.db_name))
    error_message = "The DB name must begin with a letter and contain only alphanumeric characters."
  }
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  default     = "db_admin"

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  validation {
    condition     = var.db_username != "user" && var.db_username != "admin"
    error_message = "The username 'user' and 'admin' is not allowed as it is a reserved word used by the engine."
  }
}

# Optionally, allow user to provide their own DB password.
# If not provided, a random password will be generated.
variable "db_password" {
  description = "Database administrator password"
  type        = string
  default     = null
  sensitive   = true
}

################################################################################
# EC2 Application (Backend)
################################################################################

variable "app_port" {
  description = "Port on which the backend listens"
  type        = number
  default     = 5005

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "The port must be a valid TCP port number between 1 and 65535."
  }
}

variable "app_repository" {
  description = "The repository URL for the application on the EC2 instance"
  type        = string
}

variable "app_root" {
  description = "The root directory of the backend application within the repository"
  type        = string
}

################################################################################
# Amplify (Frontend)
################################################################################

variable "amplify_repository" {
  description = "The repository URL for the Amplify app"
  type        = string
}

variable "github_access_token" {
  description = <<-EOT
    The personal access token for a third-party source control system for the Amplify app.
    The personal access token is used to create a webhook and a read-only deploy key.
    The personal access token is not stored.
    EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "amplify_app_environment_variables" {
  type        = map(string)
  description = "The environment variables for the Amplify app"
  default     = {}
}

variable "amplify_branch_environment_variables" {
  type        = map(string)
  description = "The environment variables for the Amplify branch"
  default = {
    REACT_APP_API_SERVER = "https://api.example.com"
  }
}
