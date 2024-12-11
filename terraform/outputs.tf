variable "AWS_ACCESS_KEY_ID" {
  type = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
}

variable "AWS_REGION" {
  type = string
}

variable "database_vars" {
  type = map(any)
}

# output "cloudfront_distribution_domain_name" {
#   value = module.cloudfront.cloudfront_distribution_domain_name
# }

output "alb_dns_name" {
  value = module.alb.dns_name
  
}

