provider "aws" {
  region = "eu-west-3"
}

# Create a new S3 bucket
resource "aws_s3_bucket" "portfolio_is_bucket" {
  bucket = "portfolio-nextjs-is"

  tags = {
    Name = "portfolio-nextjs-is"
  }
}

# Enable bucket ownership controls to enforce bucket owner permissions
resource "aws_s3_bucket_ownership_controls" "portfolio_is_ownership_controls" {
  depends_on = [
    aws_s3_bucket.portfolio_is_bucket
  ]

  bucket = aws_s3_bucket.portfolio_is_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Disable public access block to allow public access to the bucket
resource "aws_s3_bucket_public_access_block" "portfolio_is_public_access_block" {
  depends_on = [
    aws_s3_bucket.portfolio_is_bucket
  ]

  bucket = aws_s3_bucket.portfolio_is_bucket.id

  # Set everything to false to allow public access to the bucket
  block_public_acls       = true # Block public ACLs 
  block_public_policy     = true # Block public bucket policies
  ignore_public_acls      = true # Ignore public ACLs
  restrict_public_buckets = true # Block public and cross-account access to buckets
}

################################
# ACLs are used to have more fine-grained control over objects in the bucket | Not needed for now
# # Set the bucket Access Control List to public-read allowing public read access to the bucket
# resource "aws_s3_bucket_acl" "bucket_acl" {
#   depends_on = [
#     aws_s3_bucket_ownership_controls.bucket_ownership_controls,
#     aws_s3_bucket_public_access_block.my_bucket_public_access_block
#   ]

#   bucket = aws_s3_bucket.portfolio-bucket.id
#   acl    = "public-read"
# }
################################

# Create a bucket policy to allow read access only from CloudFront
resource "aws_s3_bucket_policy" "portfolio_is_bucket_policy" {
  depends_on = [
    aws_s3_bucket.portfolio_is_bucket,
    aws_s3_bucket_public_access_block.my_bucket_public_access_block,
    aws_cloudfront_origin_access_identity.origin_access_identity
  ]
  bucket = aws_s3_bucket.portfolio_is_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "PublicReadGetObject",
        Effect = "Allow",
        Principal = {
          AWS = "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}" # The ARN of the CloudFront origin access identity
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.portfolio_is_bucket.arn}/*",
      },
    ],
  })
}

################################
# Allow public read access to the bucket from any IP address | We do not want that
# resource "aws_s3_bucket_policy" "portfolio-bucket_policy" {
#   depends_on = [
#     aws_s3_bucket.portfolio-bucket,
#     aws_s3_bucket_public_access_block.my_bucket_public_access_block
#   ]
#   bucket = aws_s3_bucket.portfolio-bucket.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid       = "PublicReadGetObject",
#         Effect    = "Allow",
#         Principal = "*",
#         Action    = "s3:GetObject",
#         Resource  = "${aws_s3_bucket.portfolio-bucket.arn}/*",
#       },
#     ],
#   })
# }
################################

# Enable the bucket to host a static website
resource "aws_s3_bucket_website_configuration" "portfolio_is_website" {
  depends_on = [
    aws_s3_bucket.portfolio_is_bucket
  ]

  bucket = aws_s3_bucket.portfolio_is_bucket.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}


# Create an origin access identity to allow CloudFront to reach the bucket
resource "aws_cloudfront_origin_access_identity" "portfolio_is_origin_access_identity" {
  comment = "Allow CloudFront to reach the bucket"
}

# Create a CloudFront distribution to serve the static website
resource "aws_cloudfront_distribution" "portfolio_is_cloudfront" {

  # Describes the origin of the files that you want CloudFront to distribute  
  origin {
    domain_name = aws_s3_bucket.portfolio_is_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.portfolio_is_bucket.id # unique identifier for the origin

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.portfolio_is_origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true         # enable cloud front distribution directly after creation
  is_ipv6_enabled     = true         # enable IPv6 support
  default_root_object = "index.html" # default root object to serve when a request is made to the root domain


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"] # HTTP methods that CloudFront processes and forwards to the origin
    cached_methods   = ["GET", "HEAD"]            # HTTP methods for which CloudFront caches responses
    target_origin_id = aws_s3_bucket.portfolio_is_bucket.id

    # Forward the query string to the origin that is associated with this cache behavior
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https" # HTTP and HTTPS requests are automatically redirected to HTTPS
    min_ttl                = 0                   # minimum amount of time that you want objects to stay in a CloudFront cache
    default_ttl            = 3600                # default amount of time (in seconds) that you want objects to stay in CloudFront caches
    max_ttl                = 86400               # maximum amount of time (in seconds) that you want objects to stay in CloudFront caches
  }

  # Allow cloudfront to use default certificate for ssl
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Define restrictions on the geographic distribution of your content
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "portfolio-cloudfront-nextjs-is"
  }

}

