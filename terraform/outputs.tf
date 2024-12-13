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
  type = any
}

variable "database_vars2" {
  type = any
}

# variable "db_instance_endpoint" {
#   type = any
#   default = "${module.rds.db_instance_endpoint}"
# }

# variable "cluster_configuration_endpoint" {
#   type = any
#   default = "${module.elasticache.cluster_configuration_endpoint}"
# }


output "cloudfront_distribution_domain_name" {
  value = module.cloudfront.cloudfront_distribution_domain_name
}

output "alb_dns_name" {
  value = module.alb.dns_name
  
}

output "elasticache" {
  value = module.elasticache.cluster_configuration_endpoint
}

output "rds" {
  value = module.rds.db_instance_endpoint
}