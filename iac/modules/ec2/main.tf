resource "aws_instance" "app_server" {
  ami                         = "ami-0c94855ba95c71c99"
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  key_name                    = "rohtih-key-pair"
  vpc_security_group_ids      = [var.security_group_id]

#   user_data = <<-EOF
#               #!/bin/bash
#               yum update -y
#               amazon-linux-extras install docker -y
#               service docker start
#               usermod -a -G docker ec2-user
#               docker run -d -p 8000:8000 rohith123/capstone-api:latest
#               EOF
user_data = <<-EOF
  #!/bin/bash
  yum update -y
  amazon-linux-extras install docker -y
  service docker start
  usermod -a -G docker ec2-user

  # Install AWS CLI (if not installed)
  if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
  fi

  # Login to ECR
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

  # Pull latest image from your ECR repository
  docker pull <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/allstars-captsone-repo:latest

  # Run the container on port 8000
  docker run -d -p 8000:8000 <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/allstars-captsone-repo:latest
EOF


  tags = {
    Name = "all-stars-capstone"
  }
}

