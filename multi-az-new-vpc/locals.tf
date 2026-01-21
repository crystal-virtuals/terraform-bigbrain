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

locals {
  user_data = templatefile("${path.module}/user-data.tftpl", {
    project_name         = var.project_name
    environment          = var.environment
    app_repository       = var.app_repository
    app_port             = tostring(var.app_port)
    app_root             = var.app_root
    db_connection_string = "postgresql://${var.db_username}:${local.database_password}@${module.postgres.db_instance_address}:${module.postgres.db_instance_port}/${var.db_name}"
  })
}
