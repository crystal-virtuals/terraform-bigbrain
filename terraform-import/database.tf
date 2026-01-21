##################################################################
# RDS
##################################################################

resource "aws_db_instance" "database" {
  identifier = "bigbrain-database"

  engine                   = "postgres"
  engine_version           = "17.6"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  instance_class           = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 1000

  username = "postgres"
  port     = 5432

  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]

  storage_encrypted = true
  kms_key_id        = "arn:aws:kms:us-west-2:929593185725:key/1cb53e72-d229-4084-91b9-fe5e3b16b7fa"

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = "arn:aws:kms:us-west-2:929593185725:key/1cb53e72-d229-4084-91b9-fe5e3b16b7fa"
  monitoring_interval                   = 60
  monitoring_role_arn                   = "arn:aws:iam::929593185725:role/rds-monitoring-role"

  copy_tags_to_snapshot = true
}

##################################################################
# RDS Subnet Group
##################################################################

resource "aws_db_subnet_group" "database_subnet_group" {
  description = "Created from the RDS Management Console"
  name        = "rds-ec2-db-subnet-group-1"
  subnet_ids = [
    aws_subnet.subnet_rds_pvt_1.id,
    aws_subnet.subnet_rds_pvt_2.id,
    aws_subnet.subnet_rds_pvt_3.id,
    aws_subnet.subnet_rds_pvt_4.id,
  ]
}
