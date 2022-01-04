
#create security group to open port 22 for ssh and port 8008 access ngnix from web browser
resource "aws_default_security_group" "default-sg" {
    vpc_id = var.vpc_id

    #ingress will help us to ssh in vpc through local system
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
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
        cidr_blocks = ["0.0.0.0/0"]
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

#creating aws key pair to login into server
resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_loc)
}

#creating aws instance
resource "aws_instance" "myapp_server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.availability_zone

    associate_public_ip_address = true

    key_name = aws_key_pair.ssh-key.key_name
    tags = {
        Name = "${var.env_prefix}-ssh-key"
    }
}