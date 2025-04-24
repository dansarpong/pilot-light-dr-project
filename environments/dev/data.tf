data "archive_file" "create_ami_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../assets/lambda/create_ami.py"
  output_path = "${path.module}/../../assets/lambda/zip/create_ami.zip"
}

data "archive_file" "ssm_sync_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../assets/lambda/ssm_sync.py"
  output_path = "${path.module}/../../assets/lambda/zip/ssm_sync.zip"
}

data "archive_file" "failover_operations_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../assets/lambda/failover_operations.py"
  output_path = "${path.module}/../../assets/lambda/zip/failover_operations.zip"
}

data "archive_file" "initialize_failover_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../assets/lambda/initialize_failover.py"
  output_path = "${path.module}/../../assets/lambda/zip/initialize_failover.zip"
}

data "archive_file" "failback_operations_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../assets/lambda/failback_operations.py"
  output_path = "${path.module}/../../assets/lambda/zip/failback_operations.zip"
}

data "archive_file" "initialize_failback_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../assets/lambda/initialize_failback.py"
  output_path = "${path.module}/../../assets/lambda/zip/initialize_failback.zip"
}
