terraform {
  required_version = ">= 1.0"

  # Optional: store terraform state remotely in S3 (create bucket manually)
  backend "s3" {
    bucket = "your-terraform-state-bucket-name"
    key    = "capstone/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"  # Change to your AWS region
}

module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
  vpc_name   = "capstone-vpc"
}
module "ec2" {
  source        = "./modules/ec2"
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnets[0]  # You will need to create public subnets later in VPC module
}
module "rds" {
  source              = "./modules/rds"
  instance_class      = "db.t3.micro"
  db_name             = "capstone_db2"
  db_username         = "admin"
  db_password         = var.db_password  # define this in variables.tf or terraform.tfvars
  db_security_group_id = aws_security_group.rds_sg.id  # create security groups as needed
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name  # define subnet groups
}
