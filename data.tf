# Lookup our Route53 hosted zone for my domain */
data "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
}