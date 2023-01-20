#S3 Bucket
resource "aws_s3_bucket" "report_bucket" {
  bucket = "${var.report_name}.${var.domain_name}"
}

# Block all public access (bucket settings)
resource "aws_s3_bucket_public_access_block" "report_bucket_block_publics" {
  bucket = aws_s3_bucket.report_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket.report_bucket]
}

# S3 Object Ownership
resource "aws_s3_bucket_ownership_controls" "report_bucket_ownership" {
  bucket = aws_s3_bucket.report_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  depends_on = [aws_s3_bucket.report_bucket]
}

#CloudFront OAC
resource "aws_cloudfront_origin_access_control" "cloudfront_oac" {
  # for_each = toset(var.report_names)

  name                              = "${var.report_name}.${var.domain_name}.s3.ap-northeast-2.amazonaws.com"
  description                       = "${var.report_name}.${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

  depends_on = [aws_s3_bucket.report_bucket]
}

#CloudFront cache policy
data "aws_cloudfront_cache_policy" "cache_policy" {
  name = "Managed-CachingOptimized"
}

/** CloudFront Distribution **/
resource "aws_cloudfront_distribution" "report_distributions" {
  origin {
    domain_name              = aws_s3_bucket.report_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.report_bucket.id
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["${var.report_name}.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.report_bucket.id
    compress               = false
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = data.aws_cloudfront_cache_policy.cache_policy.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.ssl_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  web_acl_id = var.waf_web_acl_arn

  depends_on = [
    aws_s3_bucket.report_bucket,
    aws_cloudfront_origin_access_control.cloudfront_oac
  ]
}

#Hosted Zone ID
data "aws_route53_zone" "root_domain" {
  name = var.domain_name
}

#Route53 Record for CloudFront distribution
resource "aws_route53_record" "report_distributions_record" {
  name    = "${var.report_name}.${var.domain_name}"
  zone_id = data.aws_route53_zone.root_domain.id
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.report_distributions.domain_name
    zone_id                = aws_cloudfront_distribution.report_distributions.hosted_zone_id
    evaluate_target_health = false
  }
}

# S3 Bucket Policy for allowing access to bucket
resource "aws_s3_bucket_policy" "report_bucket_policy" {
  bucket = aws_s3_bucket.report_bucket.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "PolicyForCloudFrontPrivateContent",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipalReadOnly",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.report_bucket.arn}/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "${aws_cloudfront_distribution.report_distributions.arn}"
        }
      }
    }
  ]
}
EOF
}
