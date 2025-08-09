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

variable "my_ip" {
  description = "Your public IP for SSH access (with /32), leave empty to allow all"
  type        = string
  default     = ""
}

variable "private_network_acl_id" {
  description = "Network ACL ID for private subnet (must be provided)"
  type        = string
}
