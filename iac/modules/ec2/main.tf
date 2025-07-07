resource "aws_instance" "app_server" {
  ami           = "ami-0c94855ba95c71c99"  # ✅ Correct AMI for us-east-1
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  associate_public_ip_address = true  # ✅ This is REQUIRED for public IP

  # Install Docker and run FastAPI container
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker run -d -p 8000:8000 your-dockerhub-username/your-image-name:latest
              EOF

  tags = {
    Name = "capstone-app-server"
  }
}
