variable "db_password" {
  description = "The password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "my_ip" {
  description = "Your public IP with CIDR (/32) for SSH access. Leave empty to allow all."
  type        = string
  default     = ""
}
