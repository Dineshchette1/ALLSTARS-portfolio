variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for EC2"
  type        = string
}
