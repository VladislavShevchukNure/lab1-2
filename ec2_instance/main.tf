terraform {
  backend "s3" {
    Bucket = "lab1-artem-bucket" 
    key = "terraform.tfstate" 
    region = "us-east-1" 
    dynamodb_table = "lab1_table" 
  } 
  
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure AWS provider and creds
provider "aws" {
  region = "us-east-1"
}

# Get the latest Amazon Linux ami id
data "aws_ami" "amazon_linux" {
  most_recent = true
  
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
  
  owners = ["amazon"]

}

# Create ec2 instance
resource "aws_instance" "web" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name = "vockey"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = {
    "Name" = "New webserver"
  }
  
  user_data = <<-EOF
  #!/bin/bash
  sudo yum update -y
  sudo yum install httpd -y
  sudo systemctl start httpd
  sudo systemctl enable httpd
  echo "<html><h1>Your webserv works!</h1></html>" > /var/www/html/index.html
  EOF
}

# Security group
resource "aws_security_group" "web_sg" {
  name = "Ec2 instance sg"
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["195.189.234.102/32"]
  }
  
  ingress {
    from_port = 22
    
    to_port =22
    protocol = "tcp"
    cidr_blocks = ["195.189.234.102/32"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "website_endpoint" {
  value = aws_instance.web.public_dns
}
