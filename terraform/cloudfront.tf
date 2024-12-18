# module "cloudfront" {
#   depends_on = [module.alb]
#   source     = "terraform-aws-modules/cloudfront/aws"


#   enabled             = true
#   price_class         = "PriceClass_All"
#   retain_on_delete    = false
#   wait_for_deployment = false

#   origin = {

#     "${module.alb.dns_name}" = {
#       domain_name = "${module.alb.dns_name}"
#       origin_type = "mediastore"
#       custom_origin_config = {
#         http_port              = 80
#         https_port             = 443
#         origin_protocol_policy = "match-viewer"
#         origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
#       }
#     }

#   }


#   default_cache_behavior = {

#     target_origin_id       = "${module.alb.dns_name}"
#     viewer_protocol_policy = "allow-all"

#     allowed_methods = ["GET", "HEAD", "OPTIONS"]
#     cached_methods  = ["GET", "HEAD", "OPTIONS"]
#     compress        = true
#     query_string    = true
#   }

# }

