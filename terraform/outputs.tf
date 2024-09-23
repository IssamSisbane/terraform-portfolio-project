output "bucket_name" {
  value = aws_s3_bucket.portfolio_is_bucket.bucket
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.portfolio_is_cloudfront.domain_name
}
