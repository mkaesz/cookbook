provider "aws" {
}

resource "aws_s3_bucket" "remote_state_bucket" {
  bucket = "mkaesz-remote-state"
  acl    = "private"
}
