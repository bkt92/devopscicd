terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.3.4"
}

provider "aws" {
  region = "ap-southeast-1"
  default_tags {
    tags = {
      Environment = "Test"
      Name        = "CICD-Final"
      Managed_By  = "Terraform"
    }
  }
}

locals {
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
}

# Variable
variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(any)
  default     = ["10.0.0.0/20", "10.0.128.0/20"]
  description = "CIDR block for Public Subnet"
}

# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "main-vpc"
  }
}

# Create public subnet
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public subnet 1"
  }
}


# Select os
data "aws_ami" "amazon-linux-2" {
  most_recent = true


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

#Internet gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name"        = "default-igw"
  }
}

# route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "public-route-table"
  }
}

#route table
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# 4 EC@
resource "aws_instance" "PublicEC2-subnet-1-1" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  key_name = "sshdemokey"
  tags = {
    Name = "PublicEC2-1-1"
  }
  subnet_id = aws_subnet.public_subnet.1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  depends_on = [aws_vpc.demovpc, aws_subnet.public_subnet]
}

resource "aws_instance" "PublicEC2-subnet-1-2" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  key_name = "sshdemokey"
  tags = {
    Name = "PublicEC2-1-1"
  }
  subnet_id = aws_subnet.public_subnet.1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  depends_on = [aws_vpc.demovpc, aws_subnet.public_subnet]
}

resource "aws_instance" "PublicEC2-subnet-2-1" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  key_name = "sshdemokey"
  tags = {
    Name = "PublicEC2-1-1"
  }
  subnet_id = aws_subnet.public_subnet.2.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  depends_on = [aws_vpc.demovpc, aws_subnet.public_subnet]
}

resource "aws_instance" "PublicEC2-subnet-2-2" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"
  key_name = "sshdemokey"
  tags = {
    Name = "PublicEC2-1-1"
  }
  subnet_id = aws_subnet.public_subnet.2.id
  vpc_security_group_ids = [aws_security_group.allow_http_ssh.id]
  depends_on = [aws_vpc.demovpc, aws_subnet.public_subnet]
}

# Security group
resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  description = "Allow TLS SSH inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["14.237.3.65/32"]

  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"   
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

# IAM profile
resource "aws_iam_role" "access_ec2_terminal" {
  name = "access_ec2_terminal"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AccessEC2ViaSSM"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Role for ssh connection
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  for_each   = toset(var.iam_managed_policy_arns)
  role       = aws_iam_role.access_ec2_terminal.name
  policy_arn = each.key
}

resource "aws_iam_instance_profile" "access_ec2_terminal" {
  name = "access_ec2_terminal"
  role = aws_iam_role.access_ec2_terminal.name
}