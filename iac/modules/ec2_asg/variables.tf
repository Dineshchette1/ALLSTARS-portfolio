variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_ids" {
  description = "List of subnet IDs for ASG"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for EC2"
  type        = string
}
