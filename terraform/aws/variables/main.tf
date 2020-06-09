provider "aws" {
}

resource "aws_instance" "demo" {
  ami = "${var.ami_id_fedora32}"
  instance_type = "t2.micro"

  tags = {
    Name = "test-mkaesz"
  }
}
