database_vars = {
  "DB_NAME"     = "mydb"
  "DB_USER"     = "dbuser"
  "DB_PASSWORD" = "mypassword"
  "DB_PORT"     = "5432"
  # "DB_HOST"     = "${module.rds.db_instance_endpoint}"


  "REDIS_PORT"     = "6379"
  "REDIS_DB"       = "0"
  # "REDIS_PASSWORD" = "mypassword"
  # "REDIS_HOST"     = "${module.elasticache.cluster_configuration_endpoint}"
}


database_vars2 = [

{"name": "DB_NAME", "value": "mydb"},

{"name": "DB_USER", "value": "dbuser"},

{"name": "DB_PASSWORD", "value": "mypassword"},

{"name": "DB_PORT", "value": "5432"},

# {"name": "DB_HOST", "value": "${module.rds.db_instance_endpoint}"},


{"name": "REDIS_PORT", "value": "6379"},

# {"name": "REDIS_HOST", "value": "${module.elasticache.cluster_configuration_endpoint}"}


{"name": "BACKEND_RDS_URL", "value": "http://backend-rds:8001/test_connection/"},

{"name": "BACKEND_REDIS_URL", "value": "http://backend-redis:8002/test_connection/"}

]

