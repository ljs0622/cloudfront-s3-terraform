# create second provider with alias of "us-east-1"
provider "aws" {
    region  = "us-east-1"
    alias   = "us-east-1"
}

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

resource "aws_route53_zone" "root_domain" {
    name = var.domain_name
}

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
}

resource "aws_cloudfront_origin_access_control" "cloudfront_oacs" {
    for_each = toset(var.report_names)

    name                              = "${each.value}.${var.domain_name}.s3.ap-northeast-2.amazonaws.com"
    description                       = "${each.value}.${var.domain_name}"
    origin_access_control_origin_type = "s3"
    signing_behavior                  = "always"
    signing_protocol                  = "sigv4"
}

# /** SSL certificate **/
# module "acm_request_certificate" {
#     source                            = "cloudposse/acm-request-certificate/aws"
#     version                           = "0.17.0"
#     domain_name                       = var.domain_name
#     zone_id                           = aws_route53_zone.root_domain.id
#     process_domain_validation_options = true
#     ttl                               = "300"
#     subject_alternative_names         = [ "*.${var.domain_name}" ]


#     # To use an ACM certificate with Amazon CloudFront, you must request or import the certificate in the US East (N. Virginia) region.
#     # (https://docs.aws.amazon.com/acm/latest/userguide/acm-regions.html)
#     providers = {
#         aws = aws.us-east-1
#     }
# }

# SSL Certificate
module "acm_cert" {
    source                  = "./acm_cert"
    domain_name             = var.domain_name

# To use an ACM certificate with Amazon CloudFront, you must request or import the certificate in the US East (N. Virginia) region.
# (https://docs.aws.amazon.com/acm/latest/userguide/acm-regions.html)
    provider                = aws.us-east-1
}



# resource "aws_acm_certificate_validation" "cert_validation" {
#   certificate_arn = aws_acm_certificate.ssl_certificate.arn
#   validation_record_fqdns = [for record in aws_route53_record.records : record.fqdn]
# }