data "archive_file" "create_ami_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../assets/lambda/create_ami.py"
  output_path = "${path.module}/../../assets/lambda/create_ami.zip"
}

data "archive_file" "dr_failover_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../assets/lambda/dr_failover.py"
  output_path = "${path.module}/../../assets/lambda/dr_failover.zip"
}

data "archive_file" "dr_failback_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../assets/lambda/dr_failback.py"
  output_path = "${path.module}/../../assets/lambda/dr_failback.zip"
}
