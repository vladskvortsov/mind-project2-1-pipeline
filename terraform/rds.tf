module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.database_vars.DB_NAME # instance name

  engine                   = "postgres"
  engine_version           = "14"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  family                   = "postgres14"
  major_engine_version     = "14"
  instance_class           = "db.t3.micro" # instance type for the DB
  allocated_storage        = 20            # allocated storadge for the DB

  # variables
  db_name  = var.database_vars.DB_NAME
  username = var.database_vars.DB_USER
  port     = var.database_vars.DB_PORT
  password = var.database_vars.DB_PASSWORD

  iam_database_authentication_enabled = false
  manage_master_user_password         = false

  # maintenance_window = "Mon:00:00-Mon:03:00"
  # backup_window      = "03:00-06:00"
  deletion_protection     = false
  backup_retention_period = 0
  skip_final_snapshot     = true

  # Network configuration
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  multi_az = false

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = [module.vpc.private_subnets[1], module.vpc.private_subnets[2]]

  create_db_option_group    = false
  create_db_parameter_group = false

  tags = {
    Project     = "project2-1"
    Environment = "prod"
  }
}