# data "aws_caller_identity" "current" {}

# module "cloudfront" {
#   # depends_on = [module.s3_bucket]
#   source = "terraform-aws-modules/cloudfront/aws"


#   enabled             = true
#   price_class         = "PriceClass_All"
#   retain_on_delete    = false
#   wait_for_deployment = false
#   default_root_object = "index.html"

#   create_origin_access_control = true

#   origin_access_control = {
#     "s3_oac" : {
#       "description" : "",
#       "origin_type" : "s3",
#       "signing_behavior" : "always",
#       "signing_protocol" : "sigv4"
#     }
#   }

#   origin = {


#     "${var.frontend_bucket_name}.s3.amazonaws.com" = {
#       domain_name           = "${var.frontend_bucket_name}.s3.amazonaws.com"
#       origin_access_control = "s3_oac"

#     }
#   }

#   default_cache_behavior = {
#     path_pattern = "/*"

#     target_origin_id       = "${var.frontend_bucket_name}.s3.amazonaws.com"
#     viewer_protocol_policy = "allow-all"

#     allowed_methods = ["GET", "HEAD", "OPTIONS"]
#     cached_methods  = ["GET", "HEAD"]
#     compress        = true
#     query_string    = true
#   }

# }

