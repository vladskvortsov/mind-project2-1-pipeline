
# Fetches details about the current AWS caller identity (e.g., account ID, ARN)
data "aws_caller_identity" "current" {}

# Creates a Service Discovery HTTP Namespace for microservices under "project2-1"
resource "aws_service_discovery_http_namespace" "project2-1" {
  name = "project2-1"
}

# Configures an ECS Cluster module using the terraform-aws-modules ECS module
module "ecs_cluster" {
  depends_on = [resource.aws_service_discovery_http_namespace.project2-1, module.rds, resource.aws_elasticache_cluster.redis]
  source     = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name = "project2-1-cluster"

  # Configuration for ECS Exec command and logging
  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  # Specifies the default capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
}

# Frontend ECS Service configuration
module "ecs_service_frontend" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "frontend"
  cluster_arn = module.ecs_cluster.arn

  # Task definition resource limits
  cpu    = 1024
  memory = 2048

  enable_execute_command = true

  # Container definition for the frontend service
  container_definitions = {
    frontend = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project2-1-frontend:latest"
      health_check = {
        # Verifies service health using a CURL command
        command = ["CMD-SHELL", "curl -f http://localhost:80 || exit 1"]
      }

      # Port mapping for the service
      port_mappings = [
        {
          name          = "frontend"
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      readonly_root_filesystem  = false
      enable_cloudwatch_logging = true
      memory_reservation        = 100

      # Environment variables for the service
      environment = [
        { "name" : "BACKEND_RDS_URL", "value" : "http://backend-rds:8001/test_connection/" },
        { "name" : "BACKEND_REDIS_URL", "value" : "http://backend-redis:8002/test_connection/" }
      ]
    }
  }

  # Service discovery configuration for the service
  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.project2-1.arn
    service = {
      client_alias = {
        port     = 80
        dns_name = "frontend"
      }
      port_name      = "frontend"
      discovery_name = "frontend"
    }
  }

  # Configures the load balancer for the service
  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["frontend-tg"].arn
      container_name   = "frontend"
      container_port   = 80
    }
  }

  # IAM Role and Policies for ECS task
  tasks_iam_role_name = "ecr-pull-role"
  tasks_iam_role_policies = {
    ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }
  tasks_iam_role_statements = [
    {
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      "ecr:BatchImportUpstreamImage"]
      resources = ["*"]
    }
  ]

  # Networking configuration for ECS task
  subnet_ids            = [module.vpc.private_subnets[0]]
  create_security_group = false
  security_group_ids    = [module.frontend_sg.security_group_id]

  tags = {
    Environment = "prod"
    Project     = "project2-1"
  }
}

# Frontend ECS Service configuration
module "ecs_service_backend_rds" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "backend-rds"
  cluster_arn = module.ecs_cluster.arn

  # Task definition resource limits
  cpu    = 1024
  memory = 2048

  enable_execute_command = true

  # Container definition for the backend-rds service
  container_definitions = {

    backend-rds = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project2-1-rds-backend:latest"

      # Verifies service health using a CURL command
      health_check = {
        command = ["CMD-SHELL", "curl http://localhost:8001/test_connection/ || exit 1"]
      }

      # Port mapping for the service
      port_mappings = [
        {
          name          = "backend-rds"
          containerPort = 8001
          protocol      = "tcp"
        }
      ]

      readonly_root_filesystem  = false
      enable_cloudwatch_logging = true
      memory_reservation        = 100

      # Environment variables for the service
      environment = [

        { "name" : "DB_HOST", "value" : "${module.rds.db_instance_address}" },

        { "name" : "DB_NAME", "value" : "${var.database_vars.DB_NAME}" },

        { "name" : "DB_USER", "value" : "${var.database_vars.DB_USER}" },

        { "name" : "DB_PASSWORD", "value" : "${var.database_vars.DB_PASSWORD}" },

        { "name" : "DB_PORT", "value" : "${var.database_vars.DB_PORT}" },
      ]
    }
  }

  # Service discovery configuration for the service
  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.project2-1.arn
    service = {
      client_alias = {
        port     = 8001
        dns_name = "backend-rds"
      }
      port_name      = "backend-rds"
      discovery_name = "backend-rds"
    }
  }

  # IAM Role and Policies for ECS task
  tasks_iam_role_name = "ecr-pull-role"
  tasks_iam_role_policies = {
    ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }
  tasks_iam_role_statements = [
    {
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      "ecr:BatchImportUpstreamImage"]
      resources = ["*"]
    }
  ]

  # Networking configuration for ECS task
  subnet_ids            = [module.vpc.private_subnets[0]]
  create_security_group = false
  security_group_ids    = [module.backend_rds_sg.security_group_id]

  tags = {
    Environment = "prod"
    Project     = "project2-1"
  }
}

# backend-redis ECS Service configuration
module "ecs_service_backend_redis" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "backend-redis"
  cluster_arn = module.ecs_cluster.arn

  # Task definition resource limits
  cpu    = 1024
  memory = 2048

  enable_execute_command = true

  # Container definition for the service
  container_definitions = {

    backend-redis = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project2-1-redis-backend:latest"

      # Verifies service health using a CURL command
      health_check = {
        command = ["CMD-SHELL", "curl http://localhost:8002/test_connection/ || exit 1"]
      }

      # Port mapping for the service
      port_mappings = [
        {
          name          = "backend-redis"
          containerPort = 8002
          protocol      = "tcp"
        }
      ]

      readonly_root_filesystem  = false
      enable_cloudwatch_logging = true
      memory_reservation        = 100

      # Environment variables for the service
      environment = [

        { "name" : "REDIS_PORT", "value" : "${var.database_vars.REDIS_PORT}" },

        { "name" : "REDIS_HOST", "value" : "${aws_elasticache_cluster.redis.cache_nodes[0].address}" }
      ]
    }
  }

  # Service discovery configuration for the service
  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.project2-1.arn
    service = {
      client_alias = {
        port     = 8002
        dns_name = "backend-redis"
      }
      port_name      = "backend-redis"
      discovery_name = "backend-redis"
    }
  }

  # IAM Role and Policies for ECS task
  tasks_iam_role_name = "ecr-pull-role"
  tasks_iam_role_policies = {
    ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }
  tasks_iam_role_statements = [
    {
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      "ecr:BatchImportUpstreamImage"]
      resources = ["*"]
    }
  ]

  # Networking configuration for ECS task
  subnet_ids            = [module.vpc.private_subnets[0]]
  create_security_group = false
  security_group_ids    = [module.backend_redis_sg.security_group_id]

  tags = {
    Environment = "prod"
    Project     = "project2-1"
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "project2-1-alb"

  # ALB type and networking setup
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  # Security Group Rules for ALB
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  # ALB listener configuration
  listeners = {
    alb_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "frontend-tg"
      }
    }
  }

  # Target group configuration for the frontend service
  target_groups = {
    frontend-tg = {
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # ECS will attach the task IPs to this target group
      create_attachment = false
    }
  }
}