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

output "alb_dns_name" {
  value = module.alb.dns_name
}

output "elasticache" {
  value = module.elasticache.replication_group_primary_endpoint_address
}

output "rds" {
  value = module.rds.db_instance_address
}