# variables.tf

variable "db_password" {
  description = "The password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "ecr_repo_name" {
  description = "ECR repository name for Docker image"
  type        = string
  default     = "allstars-captsone-repo"
}

variable "docker_image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
  default     = "capstone-ecs-cluster"
}

variable "ecs_service_name" {
  description = "ECS Service name"
  type        = string
  default     = "capstone-ecs-service"
}

variable "container_name" {
  description = "Name of the container inside ECS task"
  type        = string
  default     = "capstone-app-container"
}

variable "container_port" {
  description = "Port your container listens on"
  type        = number
  default     = 8000
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Optional override for VPC ID — left for backward-compat if needed
variable "vpc_id" {
  description = "VPC ID (optional; module.vpc is used by default)"
  type        = string
  default     = ""
}

# SSH allowed IP (use your current public IP or leave empty to auto-detect)
variable "my_ip" {
  description = "Your public IP for SSH access (e.g. 1.2.3.4/32). Leave empty to auto-detect at runtime."
  type        = string
  default     = ""
}

# Other variables (leave as before)
# NOTE: db_password should be set via terraform.tfvars or -var
