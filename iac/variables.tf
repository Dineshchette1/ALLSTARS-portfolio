# ==============================
# Sensitive Variables
# ==============================

variable "db_password" {
  description = "The password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

# ==============================
# ECR / Docker Config
# ==============================

variable "ecr_repo_name" {
  description = "ECR repository name for Docker image"
  type        = string
  default     = "allstars-captsone-repo"
}

variable "docker_image_tag" {
  description = "Docker image tag (set to latest for default)"
  type        = string
  default     = "latest"
}

# ==============================
# ECS Config
# ==============================

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

# ==============================
# AWS Region
# ==============================

variable "aws_region" {
  description = "AWS region where resources are deployed"
  type        = string
  default     = "us-east-1"
}

# ==============================
# Networking (VPC / Subnets)
# ==============================

variable "vpc_id" {
  description = "VPC ID where ALB and ECS are deployed"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "ec2_instance_target_id" {
  description = "EC2 instance ID(s) to register in the target group"
  type        = list(string)
}

# ==============================
# Domain / Route 53
# ==============================

variable "domain_name" {
  description = "Domain name for Route 53 record (e.g., app.example.com)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}
