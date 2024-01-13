provider "aws" {
  region = "ap-northeast-1"
}

# resource "aws_instance" "example" {
# ami = "ami-0506f0f56e3a057a4"
# ami = "ami-07c589821f2b353aa"
# instance_type  = "t2.micro"
# vpc_security_group_ids = [aws_security_group.instance.id]
# 
# user_data = <<-EOF
# !/bin/bash
# echo "Hello, World" > index.html
# nohup busybox httpd -f -p 8080 &
# EOF
# 
# user_data_replace_on_change = true
# 
# tags = {
# Name = "terraform-example"
# }
# }

resource "aws_security_group" "instance" {
  name = "terraform-exaple-instance"

  ingress {
    from_port   = 8080
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["193.186.4.152/32"]
    # cidr_blocks = ["${aws_instance.example.public_ip/32}"]
  }
}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-07c589821f2b353aa"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p ${var.server_port} &
            EOF

  #Autosccaling Groupがある起動設定を使った場合に必須
  lifecycle {
    create_before_destroy = true
  }

}
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.default.ids

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }

}

# output "public_ip" {
#   value       = aws_autoscaling_group.example.public_ip
  # value       = aws_instance.example.public_ip
  # description = "The public IP address of the webserver"
  # sensitive   = true
# }

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

data "aws_vpc" "default" {
  default = true
}  

data "aws_subnets" "default" {

  filter {
    name = "vpc-id"
    values = [ data.aws_vpc.default.id ]
  }
  
}