resource "aws_instance" "app_server" {
  ami                         = "ami-0c94855ba95c71c99"
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  key_name                    = "rohtih-key-pair"
  vpc_security_group_ids      = [var.security_group_id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    service docker start
    usermod -a -G docker ec2-user

    # Install CloudWatch agent
    yum install -y amazon-cloudwatch-agent

    cat <<EOT > /opt/aws/amazon-cloudwatch-agent/bin/config.json
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "/ec2/allstars-capstone",
                "log_stream_name": "{instance_id}"
              },
              {
                "file_path": "/var/log/docker",
                "log_group_name": "/ec2/allstars-capstone",
                "log_stream_name": "docker-{instance_id}"
              }
            ]
          }
        }
      }
    }
    EOT

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

    # Login to ECR and run docker container
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
    docker pull <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/allstars-captsone-repo:latest
    docker run -d -p 8000:8000 <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/allstars-captsone-repo:latest
  EOF

  tags = {
    Name = "all-stars-capstone"
  }
}
