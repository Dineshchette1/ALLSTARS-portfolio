variable "instance_class" {
  default = "db.t3.micro"
}

variable "db_name" {
  default = "capstone_db2"
}

variable "db_username" {
  default = "capstone_user"
}

variable "db_password" {
  description = "The password for the database"
  type        = string
}

variable "db_security_group_id" {}

variable "db_subnet_group_name" {}
