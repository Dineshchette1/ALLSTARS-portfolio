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

# Data source to get VPC CIDR block
data "aws_vpc" "selected" {
  id = module.vpc.vpc_id
}

# Security Group for EC2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow HTTP (8000) and SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP on port 8000"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all, as HTTP is public-facing
  }

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip != "" ? var.my_ip : "0.0.0.0/0"]  # Restrict SSH to your IP if set
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# Security Group for RDS instance
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow PostgreSQL traffic only from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]  # Only allow traffic from inside VPC (PoLP)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
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

# Network ACLs for public subnet
resource "aws_network_acl" "public_acl" {
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "public-subnet-nacl"
  }
}

resource "aws_network_acl_rule" "public_in_http" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  from_port      = 8000
  to_port        = 8000
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_in_ssh" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  from_port      = 22
  to_port        = 22
  cidr_block     = var.my_ip != "" ? var.my_ip : "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_out_all" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  from_port      = 0
  to_port        = 0
  cidr_block     = "0.0.0.0/0"
}

# Network ACLs for private subnet
resource "aws_network_acl" "private_acl" {
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "private-subnet-nacl"
  }
}

resource "aws_network_acl_rule" "private_in_postgres" {
  network_acl_id = aws_network_acl.private_acl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  from_port      = 5432
  to_port        = 5432
  cidr_block     = data.aws_vpc.selected.cidr_block
}

resource "aws_network_acl_rule" "private_out_all" {
  network_acl_id = aws_network_acl.private_acl.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  from_port      = 0
  to_port        = 0
  cidr_block     = "0.0.0.0/0"
}

# Reference existing S3 bucket (no ACL resource)
data "aws_s3_bucket" "config_bucket" {
  bucket = "capstone-bucket-allstars2"
}
