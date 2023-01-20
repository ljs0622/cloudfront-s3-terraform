# cloudfront-s3-terraform

## Outline

Using CloudFront distributions, WAF, and S3, static web hosting can be configured with access to only allowed IPs.

## Composition

1. Route53 root domain(example.com)
2. Route53 record of root domain
3. Module of ACM cetrificate, WAF (should be configured in us-east-1)
   1. SSL Certificate (example.com, *.example.com)
   2. ACM CNAME record of Route53
   3. WAF(for IP whitelist)
4. Module of S3, CloudFront distributions for subdomains
   1. S3 bucket for each subdomain (aaa.example.com, bbb.example.com, ...)
   2. CloudFront distributions
   3. Route53 record for CloudFront distributions of subdomain
   4. S3 bucket policy which permits access from CloudFront only

## Follow-up Measures

* After creating Route53 root domain, external domain name server should be updated for route53 interworking.
