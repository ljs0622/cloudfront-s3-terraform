variable "report_names" {
  type = list(string)
  description = "Subdomain name list. ex) aaa.example.com, bbb.example.com"

  default = [
    "aaa",
    "bbb"
  ]
}

variable "domain_name" {
  type    = string
  description = "Root domain name. ex) example.com"
  default = "example.com"
}

variable "ip_lists" {
  type = list(string)
  description = "Allowed IP lists. The IP format is CIDR"
  default = [
    "1.2.3.4/32",
    "244.244.244.0/24"
  ]
}
