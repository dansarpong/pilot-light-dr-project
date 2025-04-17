# Get current region
data "aws_region" "current" {}

# Data Source for Availability Zones
data "aws_availability_zones" "available" {}
