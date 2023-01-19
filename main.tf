# create second provider with alias of "us-east-1"
provider "aws" {
    region  = "us-east-1"
    alias   = "us-east-1"
    profile = "terraform"
}

#S3 Bucket
resource "aws_s3_bucket" "report_buckets" {
    for_each = toset(var.report_names)
    bucket = "${each.value}.${var.domain_name}"
}

# Block all public access (bucket settings)
resource "aws_s3_bucket_public_access_block" "report_buckets_block_publics" {
    for_each = aws_s3_bucket.report_buckets
    bucket = each.value.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

# S3 Object Ownership
resource "aws_s3_bucket_ownership_controls" "report_buckets_ownerships" {
    for_each = aws_s3_bucket.report_buckets
    bucket = each.value.id

    rule {
        object_ownership = "BucketOwnerEnforced"
    }
}

#Route 53 Hosted zone
resource "aws_route53_zone" "root_domain" {
    name = var.domain_name
}

#Route 53 Record
resource "aws_route53_record" "root_domain_ns" {
    allow_overwrite = true
    zone_id = aws_route53_zone.root_domain.zone_id
    name    = var.domain_name
    type    = "NS"
    ttl     = "172800"
    
    records = [
        aws_route53_zone.root_domain.name_servers[0],
        aws_route53_zone.root_domain.name_servers[1],
        aws_route53_zone.root_domain.name_servers[2],
        aws_route53_zone.root_domain.name_servers[3]
    ]

    depends_on = [
      aws_route53_zone.root_domain
    ]
}

# SSL Certificate
module "acm_cert" {
    source                  = "./acm_cert_waf"
    domain_name             = var.domain_name
    ip_lists                = var.ip_lists

# To use an ACM certificate with Amazon CloudFront, you must request or import the certificate in the US East (N. Virginia) region.
# (https://docs.aws.amazon.com/acm/latest/userguide/acm-regions.html)
    providers = {
        aws = aws.us-east-1
    }
}

#CloudFront OAC
resource "aws_cloudfront_origin_access_control" "cloudfront_oacs" {
    for_each = toset(var.report_names)

    name                              = "${each.value}.${var.domain_name}.s3.ap-northeast-2.amazonaws.com"
    description                       = "${each.value}.${var.domain_name}"
    origin_access_control_origin_type = "s3"
    signing_behavior                  = "always"
    signing_protocol                  = "sigv4"
}

# #CloudFront cache policy
# data "aws_cloudfront_cache_policy" "cache_policy" {
#   name = "Managed-CachingOptimized"
# }

# /** CloudFront Distribution **/
# resource "aws_cloudfront_distribution" "report_distributions" {
#     for_each = aws_cloudfront_origin_access_control.cloudfront_oacs

#     origin {
#         domain_name              = each.value.name
#         origin_id                = each.value.id
#         origin_access_control_id = aws_cloudfront_origin_access_control.fe_oac.id
#     }

#   enabled             = true
#   default_root_object = "index.html"
#   aliases             = [local.domain]

#   custom_error_response {
#     error_caching_min_ttl = 0
#     error_code            = 403
#     response_code         = 200
#     response_page_path    = "/403.html"
#   }

#   default_cache_behavior {
#     allowed_methods        = ["GET", "HEAD"]
#     cached_methods         = ["GET", "HEAD"]
#     target_origin_id       = aws_s3_bucket.fe_contents.id
#     compress               = false
#     viewer_protocol_policy = "redirect-to-https"

#     origin_request_policy_id = data.aws_cloudfront_origin_request_policy.fe_origin_policy.id
#     cache_policy_id          = data.aws_cloudfront_cache_policy.fe_cache_policy.id
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     acm_certificate_arn      = module.acm_request_certificate.arn
#     minimum_protocol_version = "TLSv1.2_2021"
#     ssl_support_method       = "sni-only"
#   }

#   # Tags of cloudfront
#   tags = {
#     Name        = var.domain_namespace
#     Environment = "development"
#   }
# }