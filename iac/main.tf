terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "capstone-bucket-allstars2"
    key    = "capstone/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "capstone-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "dev"
  }
}

# Detect your current public IP for SSH access dynamically
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  my_ip_cidr = "${trimspace(data.http.my_ip.body)}/32"
}

# Data source for VPC CIDR block
data "aws_vpc" "selected" {
  id = module.vpc.vpc_id
}

# Auto-fetch private subnet NACL by subnet association
data "aws_network_acl" "private_nacl" {
  filter {
    name   = "association.subnet-id"
    values = [module.vpc.private_subnets[0]]
  }
}

# Use existing S3 bucket by name (replace with your bucket name in variables.tf or terraform.tfvars)
data "aws_s3_bucket" "config_bucket" {
  bucket = var.existing_s3_bucket_name
}

# Security group for EC2 instance with SSH allowed only from your current IP
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP (port 8000)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from my current IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# Security group for RDS instance limited to VPC CIDR (PoLP)
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow PostgreSQL traffic from VPC CIDR only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "RDS subnet group"
  }
}

module "ec2" {
  source            = "./modules/ec2"
  instance_type     = "t2.micro"
  subnet_id         = module.vpc.public_subnets[0]
  security_group_id = aws_security_group.ec2_sg.id
}

module "rds" {
  source               = "./modules/rds"
  instance_class       = "db.t3.micro"
  db_name              = "capstone_db2"
  db_username          = "capstone_user"
  db_password          = var.db_password
  db_security_group_id = aws_security_group.rds_sg.id
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

# Network ACL rule referencing the auto-fetched private NACL
resource "aws_network_acl_rule" "private_in_postgres" {
  network_acl_id = data.aws_network_acl.private_nacl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  from_port      = 5432
  to_port        = 5432
  cidr_block     = data.aws_vpc.selected.cidr_block
}

# Reference the existing S3 bucket ACL (do not recreate bucket)
resource "aws_s3_bucket_acl" "config_bucket_acl" {
  bucket = data.aws_s3_bucket.config_bucket.id
  acl    = "private"
}
