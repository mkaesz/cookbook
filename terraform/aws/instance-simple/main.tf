provider "aws" {
}

resource "aws_instance" "demo" {
  ami = "ami-012517d84e5963b0f"
  instance_type = "t2.micro"

  tags = {
    Name = "test-mkaesz"
  }
}
