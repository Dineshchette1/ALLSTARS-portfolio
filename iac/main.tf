terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "capstone-bucket-allstars2"
    key    = "capstone/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------
# auto-detect public IP if var.my_ip not provided
# -----------------------
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip_chomp = chomp(data.http.my_ip.response_body)
  # final ssh cidr in /32 format
  ssh_cidr = length(trim(var.my_ip)) > 0 ? var.my_ip : "${local.my_ip_chomp}/32"
}

# -----------------------
# Re-use your existing VPC module
# -----------------------
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

# -----------------------
# Security Groups
# -----------------------

# ALB/Loadbalancer SG (if you add ALB later)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "ALB security group (HTTP)"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP (8000) from anywhere"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

# EC2 security group: SSH restricted to your dynamic IP, HTTP open (if public app)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "EC2 security group: SSH from owner IP, HTTP from public"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow SSH from owner IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.ssh_cidr]
  }

  ingress {
    description = "Allow HTTP (app port 8000) from anywhere (adjust if needed)"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ec2-security-group" }
}

# RDS security group: only allow PostgreSQL from EC2 security group
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "RDS SG - allow PostgreSQL only from EC2 instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
    description     = "Allow Postgres from EC2 instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds-security-group" }
}

# -----------------------
# NACLs - Public and Private (basic PoLP rules)
# -----------------------

# Public NACL
resource "aws_network_acl" "public_nacl" {
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  tags = { Name = "public-nacl" }
}

resource "aws_network_acl_rule" "public_in_ssh" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "6"   # TCP
  rule_action    = "allow"
  cidr_block     = local.ssh_cidr
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "public_in_http" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 110
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = var.container_port
  to_port        = var.container_port
}

resource "aws_network_acl_rule" "public_egress_all" {
  network_acl_id = aws_network_acl.public_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Private NACL
resource "aws_network_acl" "private_nacl" {
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = { Name = "private-nacl" }
}

resource "aws_network_acl_rule" "private_in_postgres" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "6"
  rule_action    = "allow"
  # allow from your VPC CIDR so app servers in VPC can contact DB
  cidr_block     = module.vpc.cidr_block
  from_port      = 5432
  to_port        = 5432
}

resource "aws_network_acl_rule" "private_egress_all" {
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# -----------------------
# Use your existing modules (EC2, RDS)
# -----------------------

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

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "RDS subnet group"
  }
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

# -----------------------
# AWS Config - recorder + delivery channel + rules
# -----------------------

# S3 bucket for AWS Config delivery
resource "random_id" "config_bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "config_bucket" {
  bucket = "capstone-config-${random_id.config_bucket_suffix.hex}"
  acl    = "private"

  force_destroy = true

  tags = {
    Name = "capstone-config-bucket"
  }
}

# IAM role for AWS Config
resource "aws_iam_role" "aws_config_role" {
  name = "capstone-aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_config_attach" {
  role       = aws_iam_role.aws_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_configuration_recorder" "recorder" {
  name     = "capstone-config-recorder"
  role_arn = aws_iam_role.aws_config_role.arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "delivery" {
  name           = "capstone-config-delivery"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
}

resource "aws_config_configuration_recorder_status" "recorder_status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true
}

# Managed rules

resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh"
  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
}

resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"
  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
  input_parameters = jsonencode({
    tag1Key = "Environment"
  })
}

resource "aws_config_config_rule" "s3_no_public_read" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

# -----------------------
# Outputs
# -----------------------
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.instance_public_ip
  # Note: module.ec2 must export instance_public_ip; you have ec2/outputs.tf so OK
}

output "config_bucket_name" {
  value = aws_s3_bucket.config_bucket.bucket
}
