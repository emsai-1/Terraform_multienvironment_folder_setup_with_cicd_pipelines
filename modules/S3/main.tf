# Create the S3 bucket with a unique name based on the prefix and environment
resource "aws_s3_bucket" "main" {
  # Bucket names must be globally unique. This pattern helps ensure that.
  bucket = "${var.bucket_name_prefix}-${var.environment}"

  tags = var.tags
}

# Configure versioning for the bucket
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Enforce server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CRITICAL: Block all public access by default.
# This is a modern security best practice to prevent accidental data leaks.
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
