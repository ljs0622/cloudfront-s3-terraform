variable "report_names" {
    type = list(string)
    default = [
        "cshq-cloud",
        "cshq-eap",
        "cshq-linux",
        "cssc-cloud",
        "cssc-eap",
        "cssc-linux",
        "csscsal-cloud",
        "csscsal-eap",
        "csscsal-linux"
    ]
}

variable "domain_name" {
    type = string
    default = "junsleetest.link"
}

variable "ip_lists" {
    type = list(string)
    default = [
        "54.239.0.0/16",
        "165.243.192.0/24"
    ]
}