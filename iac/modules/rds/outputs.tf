output "db_instance_id" {
  description = "The ID of the RDS DB instance"
  value       = aws_db_instance.postgres.id
}
