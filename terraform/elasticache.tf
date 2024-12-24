# Defines an Elasticache parameter group for Redis
resource "aws_elasticache_parameter_group" "redis7" {
  family = "redis7"
  name   = "redis7"

  parameter {
    name  = "latency-tracking"
    value = "yes" # Enables latency tracking for Redis
  }

  tags = {
    Project     = "project2-1"
    Environment = "prod"
  }

  # Ensures the parameter group is recreated before being destroyed
  lifecycle {
    create_before_destroy = true
  }
}

# Defines a subnet group for Redis to operate within specified subnets
resource "aws_elasticache_subnet_group" "redis7" {
  name = "redis7"
  subnet_ids = [
    module.vpc.private_subnets[1],
    module.vpc.private_subnets[2]
  ]
}

# Creates an Elasticache Redis cluster
resource "aws_elasticache_cluster" "redis" {
  depends_on = [
    aws_elasticache_parameter_group.redis7,
    aws_elasticache_subnet_group.redis7
  ]

  cluster_id        = "redis"           # Unique identifier for the cluster
  engine            = "redis"           # Specifies Redis as the caching engine
  node_type         = "cache.t4g.micro" # Defines the instance type for the Redis cluster
  num_cache_nodes   = 1                 # Number of cache nodes in the cluster
  apply_immediately = true

  # Associates the parameter group and specifies the Redis engine version
  parameter_group_name = "redis7"
  engine_version       = "7.1"

  port = var.database_vars.REDIS_PORT # Specifies the port for Redis connections

  # Networking configuration
  security_group_ids = [module.elasticache_sg.security_group_id]         # Security group for Redis
  subnet_group_name  = resource.aws_elasticache_subnet_group.redis7.name # Subnet group for Redis
}