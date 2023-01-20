# create second provider with alias of "us-east-1"
provider "aws" {
  region  = "us-east-1"
  alias   = "us-east-1"
  profile = "terraform"
}

#Route 53 Hosted zone
resource "aws_route53_zone" "root_domain" {
  name = var.domain_name
}

#Route 53 Record
resource "aws_route53_record" "root_domain_ns" {
  allow_overwrite = true
  zone_id         = aws_route53_zone.root_domain.zone_id
  name            = var.domain_name
  type            = "NS"
  ttl             = "172800"

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

# SSL Certificate, WAF
module "acm_cert" {
  source      = "./acm_cert_waf"
  domain_name = var.domain_name
  ip_lists    = var.ip_lists

  depends_on = [
    aws_route53_zone.root_domain
  ]
  # To use an ACM certificate with Amazon CloudFront, you must request or import the certificate in the US East (N. Virginia) region.
  # (https://docs.aws.amazon.com/acm/latest/userguide/acm-regions.html)
  providers = {
    aws = aws.us-east-1
  }
}

#Certificate
data "aws_acm_certificate" "ssl_certificate" {
  provider = aws.us-east-1
  domain   = var.domain_name

  depends_on = [
    module.acm_cert
  ]
}

data "aws_wafv2_web_acl" "waf_web_acl" {
  provider = aws.us-east-1
  name     = "waf-ipset-allow"
  scope    = "CLOUDFRONT"

  depends_on = [
    module.acm_cert
  ]
}

# S3, CloudFront
module "s3_cloudfront" {
  for_each = toset(var.report_names)

  source              = "./s3_cloudfront"
  domain_name         = var.domain_name
  report_name         = each.value
  ssl_certificate_arn = data.aws_acm_certificate.ssl_certificate.arn
  waf_web_acl_arn     = data.aws_wafv2_web_acl.waf_web_acl.arn

  depends_on = [
    aws_route53_zone.root_domain,
    module.acm_cert
  ]
}