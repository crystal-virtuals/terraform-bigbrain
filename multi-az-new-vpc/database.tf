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
