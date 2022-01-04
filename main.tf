provider "aws" {
    region = "ap-south-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable availability_zone {}
variable env_prefix {}
variable myip {}
variable instance_type {}
variable public_key_loc {}

#creating a new VPC
resource "aws_vpc" "myapp_vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

#creating a SUBNET inside the created VPC
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp_vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.availability_zone
    tags = {
        Name = "${var.env_prefix}-subnet-1"
    }
}

/*#Creating a route table for new VPC
resource "aws_route_table" "myapp-route_table" {
    vpc_id = aws_vpc.myapp_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name = "${var.env_prefix}-rtb"
    }
}*/

#creating internet gateway for route table
resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp_vpc.id
    tags = {
        Name = "${var.env_prefix}-igw"
    }
}
/*
#subnet association with newly created route table
resource "aws_route_table_association" "association_rtb_subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_internet_gateway.myapp-igw.id
}*/

#Using Main route table
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp_vpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name = "${var.env_prefix}-main-rtb"
    }
}

#create security group to open port 22 for ssh and port 8008 access ngnix from web browser
resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp_vpc.id

    #ingress will help us to ssh in vpc through local system
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.myip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #egress will help us to flow outside VPC
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [var.myip]
        prefix_list_ids = []
    }
    tags = {
        Name = "${var.env_prefix}-sg"
    }
}

#to fetch latest ami if of latest amazon image
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
      name = "name"
      values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
}

output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image
}

#creating aws key pair to login into server
resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_loc)
}

output "aws_ec2_public_ip" {
    value = aws_instance.myapp_server.public_ip
}
#creating aws instance
resource "aws_instance" "myapp_server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.availability_zone

    associate_public_ip_address = true

    key_name = aws_key_pair.ssh-key.key_name
    tags = {
        Name = "${var.env_prefix}-ssh-key"
    }
}