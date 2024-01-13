provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_instance" "example" {
  ami = "ami-0506f0f56e3a057a4"
  instance_type  = "t2.micro"

  tags = {
    Name = "terraform-example"
  }
}
