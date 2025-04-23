output "state_machine_arn" {
  description = "ARN of the state machine"
  value       = aws_sfn_state_machine.this.arn
}
