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

data "aws_vpc" "selected" {
  id = module.vpc.vpc_id
}

# --- Security Groups ---

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP (port 8000)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # or restrict to your IP for PoLP
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip != "" ? var.my_ip : "0.0.0.0/0"] # restrict SSH by default
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

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow PostgreSQL traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block] # restrict to VPC CIDR for PoLP
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

# --- Network ACLs ---

# Public subnet ACL rules (Example)
resource "aws_network_acl_rule" "public_in_http" {
  network_acl_id = var.public_network_acl_id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  from_port      = 8000
  to_port        = 8000
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_in_ssh" {
  network_acl_id = var.public_network_acl_id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  from_port      = 22
  to_port        = 22
  cidr_block     = var.my_ip != "" ? var.my_ip : "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_out_all" {
  network_acl_id = var.public_network_acl_id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  from_port      = 0
  to_port        = 0
  cidr_block     = "0.0.0.0/0"
}

# Private subnet ACL rules (Example)
resource "aws_network_acl_rule" "private_in_postgres" {
  network_acl_id = var.private_network_acl_id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  from_port      = 5432
  to_port        = 5432
  cidr_block     = data.aws_vpc.selected.cidr_block
}

resource "aws_network_acl_rule" "private_out_all" {
  network_acl_id = var.private_network_acl_id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  from_port      = 0
  to_port        = 0
  cidr_block     = "0.0.0.0/0"
}

# --- VPC Endpoint for S3 ---
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(module.vpc.public_route_table_ids, module.vpc.private_route_table_ids)
}

# --- AWS Config ---

resource "aws_iam_role" "config_role" {
  name = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_configuration_recorder" "recorder" {
  name     = "config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "channel" {
  name           = "config-channel"
  s3_bucket_name = data.aws_s3_bucket.config_bucket.id
}

resource "aws_config_configuration_recorder_status" "status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = true
}

resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_SSH"
  }
}

resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1 = "Environment"
  })
}

# --- Reference your existing S3 bucket ---

data "aws_s3_bucket" "config_bucket" {
  bucket = "capstone-bucket-allstars2"
}
