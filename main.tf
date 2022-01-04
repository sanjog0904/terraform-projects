provider "aws" {
    region = "ap-south-1"
}

#creating a new VPC
resource "aws_vpc" "myapp_vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

module "myapp-subnet" {
    source = "./modules/subnet"
    subnet_cidr_block = var.subnet_cidr_block
    availability_zone =var.availability_zone
    env_prefix =var.env_prefix
    vpc_id =  aws_vpc.myapp_vpc.id
    default_route_table_id =  aws_vpc.myapp_vpc.default_route_table_id
}

module "myapp-server" {
    source = "./modules/webserver"
    vpc_id = aws_vpc.myapp_vpc.id
    my_ip = var.my_ip
    env_prefix = var.env_prefix
    instance_type = var.instance_type
    public_key_loc = var.public_key_loc
    subnet_id = module.myapp-subnet.subnet.id
    availability_zone = var.availability_zone
}