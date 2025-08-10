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
    cidr_blocks = ["0.0.0.0/0"]  # open HTTP to everyone
  }

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip != "" ? var.my_ip : "203.0.113.10/32"]  # your MacBook public IP only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # allow all outbound traffic
  }

  tags = {
    Name = "ec2-security-group"
  }
}

# Security Group for RDS instance
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow PostgreSQL traffic only from EC2 security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow PostgreSQL from EC2 SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "RDS subnet group"
  }
}

# NACLs and rules for public subnet
resource "aws_network_acl" "public_acl" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "public-subnet-nacl"
  }
}

resource "aws_network_acl_association" "public_subnet_associations" {
  for_each       = toset(module.vpc.public_subnets)
  subnet_id      = each.value
  network_acl_id = aws_network_acl.public_acl.id
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
  rule_number    = 1000
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  from_port      = 0
  to_port        = 0
  cidr_block     = "0.0.0.0/0"
}

# NACLs and rules for private subnet
resource "aws_network_acl" "private_acl" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "private-subnet-nacl"
  }
}

resource "aws_network_acl_association" "private_subnet_associations" {
  for_each       = toset(module.vpc.private_subnets)
  subnet_id      = each.value
  network_acl_id = aws_network_acl.private_acl.id
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
  rule_number    = 1000
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  from_port      = 0
  to_port        = 0
  cidr_block     = "0.0.0.0/0"
}

# Reference existing S3 bucket
data "aws_s3_bucket" "config_bucket" {
  bucket = "capstone-bucket-allstars2"
}

# Block public access for S3 bucket
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = data.aws_s3_bucket.config_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable S3 Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = data.aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# SNS topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "capstone-alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm - EC2 CPU High
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "EC2_CPU_Utilization_High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when EC2 CPU exceeds 70%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = module.ec2.instance_id
  }
}

# CloudWatch Alarm - RDS CPU High
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "RDS_CPU_Utilization_High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when RDS CPU exceeds 70%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_id
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

# Auto Scaling Group module for EC2 (defined below)
module "ec2_asg" {
  source            = "./modules/ec2_asg"
  instance_type     = "t2.micro"
  subnet_ids        = module.vpc.public_subnets
  security_group_id = aws_security_group.ec2_sg.id
}

