data "aws_caller_identity" "current" {}

resource "aws_service_discovery_http_namespace" "project2-1" {
  name = "project2-1"
}

module "ecs" {
  depends_on = [resource.aws_service_discovery_http_namespace.project2-1, module.rds, module.elasticache]
  source     = "terraform-aws-modules/ecs/aws"

  cluster_name = "project2-1-cluster"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    # FARGATE_SPOT = {
    #   default_capacity_provider_strategy = {
    #     weight = 50
    #   }
    # }
  }

  services = {
    frontend = {
      cpu    = 1024
      memory = 2048

      container_definitions = {

        frontend = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project2-1:frontend"
          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:80 || exit 1"]
          }

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

          environment = var.database_vars2

        }
      }

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

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["frontend-tg"].arn
          container_name   = "frontend"
          container_port   = 80
        }
      }

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

      subnet_ids = [module.vpc.private_subnets[0]]
      create_security_group = false
      security_group_ids = [module.frontend_sg.security_group_id]

      # security_group_rules = {
      #   alb_ingress_80 = {
      #     type                     = "ingress"
      #     from_port                = 80
      #     to_port                  = 80
      #     protocol                 = "tcp"
      #     source_security_group_id = module.alb.security_group_id
      #   }
      #   egress_all = {
      #     type        = "egress"
      #     from_port   = 0
      #     to_port     = 0
      #     protocol    = "-1"
      #     cidr_blocks = ["0.0.0.0/0"]
      #   }
      # }
    }

    backend-rds = {
      cpu    = 1024
      memory = 2048

      container_definitions = {

        backend-rds = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project2-1:backend-rds"
          health_check = {
            command = ["CMD-SHELL", "curl http://localhost:8001/test_connection/ || exit 1"]
          }

          port_mappings = [
            {
              name          = "backend-rds"
              containerPort = 8001
              hostPort      = 8001
              protocol      = "tcp"
            }
            # {
            #   name          = "postgres"
            #   containerPort = 5432
            #   hostPort      = 5432
            #   protocol      = "tcp"
            # }
          ]

          readonly_root_filesystem  = false
          enable_cloudwatch_logging = true
          memory_reservation        = 100

          environment = var.database_vars2
        }
      }

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

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["backend_rds-tg"].arn
          container_name   = "backend-rds"
          container_port   = 8001
        }
      }

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

      subnet_ids = [module.vpc.private_subnets[0]]
      create_security_group = false
      security_group_ids = [module.backend_rds_sg.security_group_id]
      # security_group_rules = {
      #   alb_ingress = {
      #     type                     = "ingress"
      #     from_port                = 8001
      #     to_port                  = 8001
      #     protocol                 = "tcp"
      #     source_security_group_id = module.alb.security_group_id
      #   }

      #   # postgres = {
      #   #   type                     = "ingress"
      #   #   from_port                = 5432
      #   #   to_port                  = 5432
        
      #   #   source_security_group_id = module.rds_sg.security_group_id
      #   # }
      #   egress_all = {
      #     type        = "egress"
      #     from_port   = 0
      #     to_port     = 0
      #     protocol    = "-1"
      #     cidr_blocks = ["0.0.0.0/0"]
      #   }
      # }
    }

    backend-redis = {
      cpu    = 1024
      memory = 2048

      container_definitions = {

        backend-redis = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project2-1:backend-redis"
          health_check = {
            command = ["CMD-SHELL", "curl http://localhost:8002/test_connection/ || exit 1"]
          }
          port_mappings = [
            {
              name          = "backend-redis"
              containerPort = 8002
              hostPort      = 8002
              protocol      = "tcp"
            }
          ]

          readonly_root_filesystem  = false
          enable_cloudwatch_logging = true
          memory_reservation        = 100

          environment = var.database_vars2
          # {
          #   name = "DB_HOST"
          #   value = var.AWS_REGION
          # },
          # {
          #   name = "REDIS_HOST"
          #   value = var.AWS_REGION
          # }

        }
      }

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

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["backend_redis-tg"].arn
          container_name   = "backend-redis"
          container_port   = 8002
        }
      }

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

      subnet_ids = [module.vpc.private_subnets[0]]
      create_security_group = false
      security_group_ids = [module.backend_redis_sg.security_group_id]

      # security_group_rules = {
      #   alb_ingress = {
      #     type                     = "ingress"
      #     from_port                = 8002
      #     to_port                  = 8002
      #     protocol                 = "tcp"
      #     source_security_group_id = module.alb.security_group_id
      #   }

      #   ecs_ingress = {
      #     type                     = "ingress"
      #     from_port                = 8002
      #     to_port                  = 8002
      #     protocol                 = "tcp"
      #     cidr_blocks = ["0.0.0.0/0"]
      #   }

      #   # redis = {
      #   #   type                     = "ingress"
      #   #   from_port                = 6379
      #   #   to_port                  = 6379
      #   #   protocol                 = "tcp"
      #   #   source_security_group_id = module.elasticache.security_group_id
      #   # }
      #   egress_all = {
      #     type        = "egress"
      #     from_port   = 0
      #     to_port     = 0
      #     protocol    = "-1"
      #     cidr_blocks = ["0.0.0.0/0"]
      #   }
      # }
    }

  }

  tags = {
    Environment = "prod"
    Project     = "project2-1"
  }
}


module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "project2-1-alb"

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # For example only
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }

    backend_rds = {
      from_port   = 8001
      to_port     = 8001
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }

    backend_redis = {
      from_port   = 8002
      to_port     = 8002
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

  listeners = {
    alb_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "frontend-tg"
      }
    }

    backend_rds = {
      port     = 8001
      protocol = "HTTP"

      forward = {
        target_group_key = "backend_rds-tg"
      }
    }

    backend_redis = {
      port     = 8002
      protocol = "HTTP"

      forward = {
        target_group_key = "backend_redis-tg"
      }
    }

  }

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

      # There's nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }


    backend_rds-tg = {
      backend_protocol                  = "HTTP"
      backend_port                      = 8001
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/test_connection/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # There's nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }

    backend_redis-tg = {
      backend_protocol                  = "HTTP"
      backend_port                      = 8002
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/test_connection/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # There's nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
  }
}
