data "aws_caller_identity" "current" {}






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


################################################################################
# Cluster
################################################################################

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = project2-1-cluster

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
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
      memory = 4096

      # Container definition(s)
      container_definitions = {

        frontend = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com/project2-1:frontend"

          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost/health || exit 1"]
          }

          port_mappings = [
            {
              name          = frontend
              containerPort = 80
              hostPort      = 80
              protocol      = "tcp"
            }
          ]

          # Example image used requires access to write to root filesystem
          readonly_root_filesystem = false

          # dependencies = [{
          #   containerName = "fluent-bit"
          #   condition     = "START"
          # }]

          enable_cloudwatch_logging = false

          memory_reservation = 100
        }
      }

      service_connect_configuration = {
        namespace = project2-1
        service = {
          client_alias = {
            port     = 80
            dns_name = frontend
          }
          port_name      = 80
          discovery_name = frontend
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups["ex_ecs"].arn
          container_name   = frontend
          container_port   = 80
        }
      }

      tasks_iam_role_name        = "ecs-tasks"
      tasks_iam_role_policies = {
        ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
      }
      tasks_iam_role_statements = [
        {
          actions   = ["s3:List*"]
          resources = ["arn:aws:s3:::*"]
        }
      ]

      subnet_ids = module.vpc.private_subnets
      security_group_rules = {
        alb_ingress_3000 = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          description              = "Service port"
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

  tags = prod
}





################################################################################
# Supporting Resources
################################################################################




module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = project2-1-alb

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
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex_ecs"
      }
    }
  }

  target_groups = {
    ex_ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = 80
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = false

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

      # Theres nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
  }

  tags = prod
}
