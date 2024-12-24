module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "project2-1-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.AWS_REGION}a", "${var.AWS_REGION}b", "${var.AWS_REGION}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}

# Security Group for RDS instance
module "rds_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.backend_rds_sg.security_group_id
    },
  ]

  egress_rules = ["all-all"]
}

# Security Group for Elasticache
module "elasticache_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "elasticache-sg"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      source_security_group_id = module.backend_redis_sg.security_group_id
    },
  ]

  egress_rules = ["all-all"]
}

# Security Group for ECS frontend service
module "frontend_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "frontend-sg"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [

    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.alb.security_group_id
    },
  ]

  egress_rules = ["all-all"]
}

# Security Group for ECS backend-rds service
module "backend_rds_sg" {
  depends_on = [module.frontend_sg]
  source     = "terraform-aws-modules/security-group/aws"

  name   = "backend-rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8001
      to_port                  = 8001
      protocol                 = "tcp"
      source_security_group_id = module.frontend_sg.security_group_id
    },
  ]

  egress_rules = ["all-all"]
}

# Security Group for ECS backend-redis service
module "backend_redis_sg" {
  depends_on = [module.frontend_sg]
  source     = "terraform-aws-modules/security-group/aws"

  name   = "backend-redis-sg"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8002
      to_port                  = 8002
      protocol                 = "tcp"
      source_security_group_id = module.frontend_sg.security_group_id
    },
  ]
  egress_rules = ["all-all"]
}

