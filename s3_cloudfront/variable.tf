variable "domain_name" {
  type        = string
  description = "A domain name for which the certificate should be issued"

  validation {
    condition     = !can(regex("[A-Z]", var.domain_name))
    error_message = "Domain name must be lower-case."
  }
}

variable "report_name" {
  type = string
}

variable "ssl_certificate_arn" {
  type = string
}

variable "waf_web_acl_arn" {
  type = string
}
