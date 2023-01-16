output "route53_zone" {
  description = "Zone id of Route53"
  value       = data.aws_route53_zone.hosted_zone.zone_id
}