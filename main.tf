provider "aws" {
    region = "ap-south-1"
}

variable "subnet_cidr_blocks" {
    description = "subnet cidr blocks"
}

resource "aws_vpc" "dev_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "dev-env"
    }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.dev_vpc.id
    cidr_block = var.subnet_cidr_blocks
    availability_zone = "ap-south-1a"
    tags = {
        Name = "dev-env-subnet-1"
    }  
}

#creating subnet inside existing vpc
data "aws_vpc" "existibg_vpc" {
    default = true
}

resource "aws_subnet" "dev-subnet-2" {
    vpc_id = data.aws_vpc.existibg_vpc.id
    cidr_block = "172.31.48.0/20"
    availability_zone = "ap-south-1a"
    tags = {
        Name = "default-subnet"
    }  
}