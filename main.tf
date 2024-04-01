terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
    # version = "~> 4.31.0"
   }
 }
}

provider "aws" {
  alias = "ap"
  region = "ap-southeast-3"
}

data "aws_region" "current" {}

# 1. Create VPC

resource "aws_vpc" "main" {
  cidr_block = "10.100.0.0/16" 
  enable_dns_hostnames = true

  tags = {
    Name = "AWS VPC"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id  
}

# 3. Create Custom Route Table
resource "aws_route_table" "route_table" {
 vpc_id = aws_vpc.main.id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gateway.id
 }
}

# 4. Create a subnet
resource "aws_subnet" "main" {
  vpc_id = aws_vpc.main.id
  cidr_block = aws_vpc.main.cidr_block
  availability_zone = "${data.aws_region.current.name}a"
}

# 5. Associate subnet with Route table
resource "aws_route_table_association" "route_table_association" {
 subnet_id      = aws_subnet.main.id
 route_table_id = aws_route_table.route_table.id
}

#generate tls_private_key
resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "aws_key" {
  key_name = "ansible-ssh-key"
  public_key = tls_private_key.key.public_key_openssh
}

# resource "aws_security_group" "allow_ssh" {
#   name = "allow_ssh"
#   description = "Allow SSH traffic"
#   vpc_id = aws_vpc.main.id
#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     cidr_blocks = ["0.0.0.0/0"]
#     from_port   = 0
#     protocol    = "-1"
#     to_port     = 0
#   }
# }

# resource "aws_security_group" "allow_http" {
#   name = "allow_http"
#   description = "Allow HTTP traffic"
#   vpc_id = aws_vpc.main.id
#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     cidr_blocks = ["0.0.0.0/0"]
#     from_port   = 0
#     protocol    = "-1"
#     to_port     = 0
#   }
# }

# 6. Create Security group to allow port 22,80,443
 resource "aws_security_group" "allow_web" {
    name = "allow_web_traffic"
    description = "Allow web inbound traffic"
    vpc_id = aws_vpc.main.id
    ingress {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port   = 0
      protocol    = "-1"
      to_port     = 0
    }

    tags = {
        Name = "allow_web"
      }
  }

# 7. create Ubuntu server and install nginx
resource "aws_instance" "server" {
  count = var.instance_count
  ami = var.ami
  instance_type = var.instance_type # here we define with the variable instance_count how many servers we want to create (see variables.tf)
  key_name = aws_key_pair.aws_key.key_name
  associate_public_ip_address = true
  subnet_id = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  
  provisioner "remote-exec" {
      inline = [
        "sudo apt-get update",
        "sudo apt-get install -y nginx"
      ]
    }

  tags = {
    Name = element(var.instance_tags, count.index)
  }
}
