data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

resource "aws_service_discovery_http_namespace" "project2-1" {
  name        = "project2-1"
}


module "ecs" {
  depends_on = [resource.aws_service_discovery_http_namespace.project2-1]
  source = "terraform-aws-modules/ecs/aws"

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

          readonly_root_filesystem = false
          enable_cloudwatch_logging = true
          memory_reservation = 100
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

      tasks_iam_role_name        = "ecr-pull-role"
      tasks_iam_role_policies = {
        ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess" 
      }
      tasks_iam_role_statements = [
        {
          actions   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchImportUpstreamImage"]
          resources = ["*"]
        }
      ]

      subnet_ids = module.vpc.private_subnets

      # vpc_security_group_ids = [module.ecs_sg.id, module.rds_sg.id, module.elasticache.security_group_id]
      security_group_rules = {
        alb_ingress_80 = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          # cidr_blocks = ["0.0.0.0/0"]
          source_security_group_id = module.alb.security_group_id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
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
            command = ["CMD-SHELL", "curl -f http://localhost:8001/test_connection/ || exit 1"]
          }

          port_mappings = [
            {
              name          = "backend-rds"
              containerPort = 8001
              hostPort      = 8001
              protocol      = "tcp"
            }
          ]

          readonly_root_filesystem = false
          enable_cloudwatch_logging = true
          memory_reservation = 100
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

      tasks_iam_role_name        = "ecr-pull-role"
      tasks_iam_role_policies = {
        ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess" 
      }
      tasks_iam_role_statements = [
        {
          actions   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchImportUpstreamImage"]
          resources = ["*"]
        }
      ]

      subnet_ids = module.vpc.private_subnets

      # vpc_security_group_ids = [module.ecs_sg.id, module.rds_sg.id, module.elasticache.security_group_id]
      security_group_rules = {
        alb_ingress = {
          type                     = "ingress"
          from_port                = 8001
          to_port                  = 8001
          protocol                 = "tcp"
          source_security_group_id = module.alb.security_group_id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }

    backend-redis = {
      cpu    = 1024
      memory = 2048

      container_definitions = {

        backend-rds = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project2-1:backend-redis"
          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:8002/test_connection/ || exit 1"]
          }

          port_mappings = [
            {
              name          = "backend-redis"
              containerPort = 8002
              hostPort      = 8002
              protocol      = "tcp"
            }
          ]

          readonly_root_filesystem = false
          enable_cloudwatch_logging = true
          memory_reservation = 100
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

      tasks_iam_role_name        = "ecr-pull-role"
      tasks_iam_role_policies = {
        ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess" 
      }
      tasks_iam_role_statements = [
        {
          actions   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchImportUpstreamImage"]
          resources = ["*"]
        }
      ]

      subnet_ids = module.vpc.private_subnets

      # vpc_security_group_ids = [module.ecs_sg.id, module.rds_sg.id, module.elasticache.security_group_id]
      security_group_rules = {
        alb_ingress = {
          type                     = "ingress"
          from_port                = 8002
          to_port                  = 8002
          protocol                 = "tcp"
          source_security_group_id = module.alb.security_group_id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }

    
  }

  tags = {
    Environment = "prod"
    Project     = "project2-1"
  }
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"

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

    postgres = {
      from_port   = 5432
      to_port     = 5432
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }

    redis = {
      from_port   = 6379
      to_port     = 6379
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










# module "key_pair" {
#   source = "terraform-aws-modules/key-pair/aws"

#   key_name           = "key"
#   create_private_key = true
# }

# resource "aws_iam_instance_profile" "ecr-pull-instance-profile" {
#   name = "ecr-pull-instance-profile"
#   role = aws_iam_role.ecr-pull-role.name
# }

# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "ecr-pull-role" {
#   name               = "ecr-pull-role"
#   path               = "/"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

# module "ec2_instance" {
#   source = "terraform-aws-modules/ec2-instance/aws"

#   name  = "project1-2-backend"
#   count = 1

#   ami                         = "ami-08eb150f611ca277f"
#   instance_type               = "t3.micro"
#   key_name                    = module.key_pair.key_pair_name
#   vpc_security_group_ids      = [module.ec2_sg.security_group_id]
#   subnet_id                   = module.vpc.public_subnets[0]
#   iam_instance_profile        = resource.aws_iam_instance_profile.ecr-pull-instance-profile.name
#   associate_public_ip_address = true
#   user_data_replace_on_change = true
#   user_data                   = <<-EOT
#     #!/bin/bash
#     sudo apt update -y
#     sudo apt install -y docker.io docker-compose
#     sudo snap install aws-cli --classic
#     sudo aws configure set aws_access_key_id ${var.AWS_ACCESS_KEY_ID}
#     sudo aws configure set aws_secret_access_key ${var.AWS_SECRET_ACCESS_KEY}
#     sudo aws ecr get-login-password --region ${var.AWS_REGION} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com
#     cd /home/ubuntu/
#     echo "SECRET_KEY=my-secret-key
#     DEBUG=False

#     DB_NAME=${var.database_vars.DB_NAME}
#     DB_USER=${var.database_vars.DB_USER}
#     DB_PASSWORD=${var.database_vars.DB_PASSWORD}
#     DB_HOST=postgres
#     DB_PORT=${var.database_vars.DB_PORT}

#     REDIS_HOST=redis
#     REDIS_PORT=${var.database_vars.REDIS_PORT}
#     REDIS_DB=${var.database_vars.REDIS_DB}
#     REDIS_PASSWORD=${var.database_vars.REDIS_PASSWORD}

#     CORS_ALLOWED_ORIGINS=http://${data.terraform_remote_state.tf-frontend.outputs.cloudfront_distribution_domain_name}" > vars.env

#     echo '# version: '3.8'
#     services:
#       postgres:
#         env_file:
#         - vars.env
#         image: postgres:13
#         container_name: postgres
#         environment:
#             POSTGRES_DB: ${var.database_vars.DB_NAME}
#             POSTGRES_USER: ${var.database_vars.DB_USER}
#             POSTGRES_PASSWORD: ${var.database_vars.DB_PASSWORD}
#         volumes:
#         - postgres_data:/var/lib/postgresql/data
#         ports:
#         - "5432:5432"
#         networks:
#         - backend

#       redis:
#         env_file:
#         - vars.env
#         image: redis:6.2
#         container_name: redis
#         command: redis-server --requirepass ${var.database_vars.REDIS_PASSWORD}
#         ports:
#         - "6379:6379"
#         networks:
#         - backend

#       backend_rds:
#         env_file:
#         - vars.env
#         image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project1-2-backend:backend-rds
#         container_name: backend_rds
#         ports:
#         - "8000:8000"
#         networks:
#         - backend
#         entrypoint: ["sh", "-c", "sleep 10 && python manage.py runserver 0.0.0.0:8000"]

#       backend_redis:
#         env_file:
#         - vars.env
#         image: ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project1-2-backend:backend-redis
#         container_name: backend_redis
#         ports:
#         - "8003:8003"
#         networks:
#         - backend
#         entrypoint: ["sh", "-c", "sleep 10 && python manage.py runserver 0.0.0.0:8003"]

#     volumes:
#       postgres_data:
#         driver: local

#     networks:
#       backend:
#         driver: bridge' > docker-compose.yml
#     docker-compose up -d
#   EOT

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }






# locals {
#   # region = "eu-west-1"
#   name   = "ex-${basename(path.cwd)}"

#   vpc_cidr = "10.0.0.0/16"
#   azs      = slice(data.aws_availability_zones.available.names, 0, 3)

#   container_name = "ecsdemo-frontend"
#   container_port = 3000

#   tags = {
#     Name       = local.name
#     Example    = local.name
#     Repository = "https://github.com/terraform-aws-modules/terraform-aws-ecs"
#   }
# }





# ################################################################################
# # Cluster
# ################################################################################

# module "ecs_cluster" {
#   source = "terraform-aws-modules/ecs/aws"

#   cluster_name = project2-1-cluster

#   # Capacity provider
#   fargate_capacity_providers = {
#     FARGATE = {
#       default_capacity_provider_strategy = {
#         weight = 50
#         base   = 20
#       }
#     }
#   }

#   # tags = local.tags
# }

# # ################################################################################
# # # Service
# # ################################################################################

# # module "ecs_service" {
# #   source = "../../modules/service"

# #   name        = frontend
# #   cluster_arn = module.ecs_cluster.arn

# #   cpu    = 1024
# #   memory = 1024

# #   # Enables ECS Exec
# #   enable_execute_command = true

# #   # Container definition(s)
# #   container_definitions = {

# #     fluent-bit = {
# #       cpu       = 512
# #       memory    = 1024
# #       essential = true
# #       image     = nonsensitive(data.aws_ssm_parameter.fluentbit.value)
# #       firelens_configuration = {
# #         type = "fluentbit"
# #       }
# #       memory_reservation = 50
# #       user               = "0"
# #     }

# #     (local.container_name) = {
# #       cpu       = 512
# #       memory    = 1024
# #       essential = true
# #       image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"
# #       port_mappings = [
# #         {
# #           name          = local.container_name
# #           containerPort = local.container_port
# #           hostPort      = local.container_port
# #           protocol      = "tcp"
# #         }
# #       ]

# #       # Example image used requires access to write to root filesystem
# #       readonly_root_filesystem = false

# #       dependencies = [{
# #         containerName = "fluent-bit"
# #         condition     = "START"
# #       }]

# #       enable_cloudwatch_logging = false
# #       log_configuration = {
# #         logDriver = "awsfirelens"
# #         options = {
# #           Name                    = "firehose"
# #           region                  = local.region
# #           delivery_stream         = "my-stream"
# #           log-driver-buffer-limit = "2097152"
# #         }
# #       }

# #       linux_parameters = {
# #         capabilities = {
# #           add = []
# #           drop = [
# #             "NET_RAW"
# #           ]
# #         }
# #       }

# #       # Not required for fluent-bit, just an example
# #       volumes_from = [{
# #         sourceContainer = "fluent-bit"
# #         readOnly        = false
# #       }]

# #       memory_reservation = 100
# #     }
# #   }

# #   service_connect_configuration = {
# #     namespace = aws_service_discovery_http_namespace.this.arn
# #     service = {
# #       client_alias = {
# #         port     = local.container_port
# #         dns_name = local.container_name
# #       }
# #       port_name      = local.container_name
# #       discovery_name = local.container_name
# #     }
# #   }

# #   load_balancer = {
# #     service = {
# #       target_group_arn = module.alb.target_groups["ex_ecs"].arn
# #       container_name   = local.container_name
# #       container_port   = local.container_port
# #     }
# #   }

# #   subnet_ids = module.vpc.private_subnets
# #   security_group_rules = {
# #     alb_ingress_3000 = {
# #       type                     = "ingress"
# #       from_port                = local.container_port
# #       to_port                  = local.container_port
# #       protocol                 = "tcp"
# #       description              = "Service port"
# #       source_security_group_id = module.alb.security_group_id
# #     }
# #     egress_all = {
# #       type        = "egress"
# #       from_port   = 0
# #       to_port     = 0
# #       protocol    = "-1"
# #       cidr_blocks = ["0.0.0.0/0"]
# #     }
# #   }

# #   service_tags = {
# #     "ServiceTag" = "Tag on service level"
# #   }

# #   tags = local.tags
# # }

# ################################################################################
# # Standalone Task Definition (w/o Service)
# ################################################################################

# module "ecs_task_definition" {
#   source = "terraform-aws-modules/ecs/service"

#   # Service
#   name        = "frontend"
#   cluster_arn = module.ecs_cluster.arn

#   # Task Definition
#   volume = {
#     ex-vol = {}
#   }

#   runtime_platform = {
#     cpu_architecture        = "ARM64"
#     operating_system_family = "LINUX"
#   }

#   # Container definition(s)
#   container_definitions = {
#     frontend = {
#       image = "nginxdemos/hello"  #"${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project2-1:frontend"

#       mount_points = [
#         {
#           sourceVolume  = "ex-vol",
#           containerPath = "/app"
#         }
#       ]

#       # command    = ["echo hello world"]
#       entrypoint = ["python", "manage.py", "runserver", "0.0.0.0:80"]
#     }
#   }

#   subnet_ids = module.vpc.private_subnets

#   security_group_rules = {
  

#     all_http = {
#       type = "ingress"
#       from_port   = 80
#       to_port     = 80
#       ip_protocol = "tcp"
#       cidr_ipv4   = "0.0.0.0/0"
#     }

#     egress_all = {
#       type        = "egress"
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   # tags = local.tags
# }













