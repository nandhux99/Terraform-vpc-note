terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "publicsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
availability_zone = "us-east-1a"
  tags = {
    Name = "publicsub"
  }
}

resource "aws_subnet" "privatesub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
availability_zone = "us-east-1b"
  tags = {
    Name = "privatesub"
  }
}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "my-igw"
  }
}

resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
  tags = {
    Name = "PublicRT"
  }
}

resource "aws_route_table_association" "PublicRTAssociate" {
  subnet_id      = aws_subnet.publicsub .id
  route_table_id = aws_route_table.PublicRT.id
}

resource "aws_eip" "myeip" {
  vpc      = true
}
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.publicsub.id

  tags = {
    Name = "nat gw"
  }

  
}
resource "aws_route_table" "PrivateRT" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = "PrivateRT"
  }
}

resource "aws_route_table_association" "PrivateRTAssociate" {
  subnet_id      = aws_subnet.privatesub.id
  route_table_id = aws_route_table.PrivateRT.id
}


resource "aws_security_group" "public-sg" {
  name        = "public-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] 
  }
   ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] 
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "public-sg"
  }
}
resource "aws_security_group" "private-sg" {
  name        = "private-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.0.1.0/24"] 
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "private-sg"
  }
}
resource "aws_instance" "pubEc2"{
    ami = "ami-02396cdd13e9a1257"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.publicsub.id
    key_name  =  "mykey"
    vpc_security_group_ids= [aws_security_group.public-sg.id]
    associate_public_ip_address = true
}
resource "aws_instance" "priEc2"{
    ami = "ami-02396cdd13e9a1257"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.privatesub.id
    key_name  =  "mykey"
    vpc_security_group_ids=[aws_security_group.private-sg.id]
    
}