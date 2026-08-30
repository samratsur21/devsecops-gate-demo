provider "aws" {
  region = "eu-west-3"
}

resource "aws_s3_bucket" "payment_records" {
  bucket = "acme-payment-records"
}

resource "aws_s3_bucket_public_access_block" "payment_records" {
  bucket                  = aws_s3_bucket.payment_records.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Application security group"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "payments" {
  identifier          = "payments-db"
  engine              = "postgres"
  instance_class      = "db.t3.medium"
  allocated_storage   = 20
  username            = "appuser"
  password            = "SuperSecret123!"
  storage_encrypted   = false
  publicly_accessible = true
  skip_final_snapshot = true
}
