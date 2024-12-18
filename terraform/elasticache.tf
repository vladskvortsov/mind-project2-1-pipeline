module "elasticache" {
  source = "terraform-aws-modules/elasticache/aws"

  cluster_id               = "redis"
  create_cluster           = true
  create_replication_group = false

  engine_version = "7.1"
  node_type      = "cache.t4g.micro"

  port = var.database_vars.REDIS_PORT

  #   maintenance_window = "sun:05:00-sun:09:00"
  apply_immediately = true

  # Security group
  vpc_id = module.vpc.vpc_id

  create_security_group = false

  security_group_ids = [module.elasticache_sg.security_group_id]
  # security_group_rules = {
  #   ingress_vpc = {
  #     # Default type is `ingress`
  #     # Default port is based on the default engine port
  #     description = "VPC traffic"
  #     cidr_ipv4   = "0.0.0.0/0"
  #   }
  # }

  # Subnet Group
  subnet_ids = [module.vpc.private_subnets[1], module.vpc.private_subnets[2]]

  # Parameter Group
  create_parameter_group = true
  parameter_group_family = "redis7"
  parameters = [
    {
      name  = "latency-tracking"
      value = "yes"
    }
  ]

  tags = {
    Project     = "project2-1"
    Environment = "prod"
  }
}