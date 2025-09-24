# Simple Terraform configuration for testing S3 native locking
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Test resource 1: S3 Bucket
resource "aws_s3_bucket" "test_bucket" {
  bucket = "tf-locking-test-${var.environment}-${random_id.suffix.hex}"

  tags = {
    Environment = var.environment
    Project     = "s3-locking-poc"
  }
}

resource "aws_s3_bucket_versioning" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Test resource 2: VPC
resource "aws_vpc" "test_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name        = "test-vpc-${var.environment}"
    Environment = var.environment
  }
}

# Test resource 3: Security Group
resource "aws_security_group" "test_sg" {
  name        = "test-sg-${var.environment}"
  description = "Test security group for S3 locking POC"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
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

  tags = {
    Environment = var.environment
  }
}

# Random suffix for unique names
resource "random_id" "suffix" {
  byte_length = 4
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.test_bucket.bucket
}

output "vpc_id" {
  value = aws_vpc.test_vpc.id
}

output "security_group_id" {
  value = aws_security_group.test_sg.id
}

output "environment" {
  value = var.environment
}