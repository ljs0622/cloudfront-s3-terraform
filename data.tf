# Lookup our Route53 hosted zone for my domain */
data "aws_route53_zone" "root_domain_data" {
  name = var.domain_name
}