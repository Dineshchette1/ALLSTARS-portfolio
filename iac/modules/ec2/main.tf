resource "aws_instance" "app_server" {
  ami           = "ami-0c94855ba95c71c99"  # Amazon Linux 2 - check your region for latest AMI
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  # User data to install docker and run your docker container
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
