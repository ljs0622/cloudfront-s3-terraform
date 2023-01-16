variable "domain_name" {
    type        = string
    description = "A domain name for which the certificate should be issued"

    validation {
        condition     = ! can(regex("[A-Z]", var.domain_name))
        error_message = "Domain name must be lower-case."
    }
}

variable "provider_name" {
    type        = string
    description = "Provider for which the certificate should be issued"
}