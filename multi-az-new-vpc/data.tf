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
