output "db_instance_id" {
  description = "The ID of the RDS DB instance"
  value       = aws_db_instance.postgres.id
  description = "The RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "The name of the initial database"
  value       = aws_db_instance.this.db_name
}

