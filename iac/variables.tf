# Database
variable "db_password" {
  description = "The password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

# ECR
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

# ECS
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

# Networking (optional if auto-discovery is enabled)
variable "vpc_id" {
  description = "VPC ID where ALB is deployed (optional if auto-discovered)"
  type        = string
  default     = null
}

variable "public_subnets" {
  description = "List of public subnet IDs for ALB (optional if auto-discovered)"
  type        = list(string)
  default     = []
}

# EC2 Target Group (optional if auto-discovered)
variable "ec2_instance_target_id" {
  description = "EC2 instance ID(s) to register in the target group (optional if auto-discovered)"
  type        = list(string)
  default     = []
}

# Route 53
variable "domain_name" {
  description = "Domain name for Route 53 record"
  type        = string
  default     = null
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID (optional if auto-discovered)"
  type        = string
  default     = null
}
