resource "aws_instance" "app_server" {
  ami                         = "ami-0c94855ba95c71c99"
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  key_name                    = "rohtih-key-pair"
  vpc_security_group_ids      = [var.security_group_id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker run -d -p 8000:8000 rohith123/capstone-api:latest
              EOF

  tags = {
    Name = "all-stars-capstone"
  }
}
