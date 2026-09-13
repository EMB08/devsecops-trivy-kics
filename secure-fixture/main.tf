terraform {
  required_version = ">= 1.0"
}

resource "aws_s3_bucket" "secure_bucket" {
  bucket = "devsecops-secure-fixture"
}
