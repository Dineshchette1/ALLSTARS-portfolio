variable "db_password" {
  description = "The password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
  default     = "capstone-ecs-cluster"
}

variable "existing_s3_bucket_name" {
  description = "Name of existing S3 bucket for terraform backend and config"
  type        = string
  default     = "capstone-bucket-allstars2"
}

variable "my_ip" {
  description = "Your public IP for SSH access (optional, auto-detected if empty)"
  type        = string
  default     = ""
}
