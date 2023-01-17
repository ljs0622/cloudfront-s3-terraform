#S3 Bucket
resource "aws_s3_bucket" "report_bucket" {
    bucket = "${var.report_name}.${var.domain_name}"
}

# Block all public access (bucket settings)
resource "aws_s3_bucket_public_access_block" "report_buckets_block_publics" {
    bucket = aws_s3_bucket.report_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

# S3 Object Ownership
resource "aws_s3_bucket_ownership_controls" "report_buckets_ownerships" {
    bucket = aws_s3_bucket.report_bucket.id

    rule {
        object_ownership = "BucketOwnerEnforced"
    }
}

#CloudFront OAC
resource "aws_cloudfront_origin_access_control" "cloudfront_oacs" {
    # for_each = toset(var.report_names)

    name                              = "${var.report_name}.${var.domain_name}.s3.ap-northeast-2.amazonaws.com"
    description                       = "${var.report_name}.${var.domain_name}"
    origin_access_control_origin_type = "s3"
    signing_behavior                  = "always"
    signing_protocol                  = "sigv4"
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
        origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_oacs.id
    }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [local.domain]

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 200
    response_page_path    = "/403.html"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.fe_contents.id
    compress               = false
    viewer_protocol_policy = "redirect-to-https"

    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.fe_origin_policy.id
    cache_policy_id          = data.aws_cloudfront_cache_policy.fe_cache_policy.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = module.acm_request_certificate.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  # Tags of cloudfront
  tags = {
    Name        = var.domain_namespace
    Environment = "development"
  }
}
