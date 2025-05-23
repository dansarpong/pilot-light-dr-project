# Primary DB Instance
resource "aws_db_instance" "primary" {
  count                   = var.is_dr == false ? 1 : 0

  identifier              = "${var.environment}-db"
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  storage_type            = var.storage_type
  db_name                 = var.db_name
  username                = var.username
  password                = var.password
  multi_az                = var.multi_az
  vpc_security_group_ids  = var.security_group_ids
  parameter_group_name    = "default.${var.engine}${var.engine_version}"
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  backup_retention_period = var.backup_retention_days
  publicly_accessible     = false
  skip_final_snapshot     = true

  tags = var.tags
}

# Cross-Region Read Replica
resource "aws_db_instance" "cross_region_replica" {
  count                   = var.is_dr == true ? 1 : 0

  identifier              = "${var.environment}-db-replica"
  replicate_source_db     = var.source_db_arn
  instance_class          = var.instance_class
  storage_type           = var.storage_type
  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  publicly_accessible    = false
  skip_final_snapshot    = true

  # Add lifecycle block to prevent modifications that could cause issues
  lifecycle {
    ignore_changes = [
      replicate_source_db
    ]
  }

  tags = var.tags
}

# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}
