output "db_instance_id" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "The name of the initial database created"
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "The master username for the RDS instance"
  value       = aws_db_instance.this.username
  sensitive   = true
}
