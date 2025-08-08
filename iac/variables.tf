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
  default = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID where ALB is deployed"
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

variable "domain_name" {
  description = "Domain name for Route 53 record"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
}
