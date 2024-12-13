module "cloudfront" {
  depends_on = [module.alb]
  source = "terraform-aws-modules/cloudfront/aws"


  enabled             = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false
#   default_root_object = "index.html"

#   create_origin_access_control = true

#   origin_access_control = {
#     "alb_oac" : {
#       "description" : "",
#       "origin_type" : "mediastore",
#       "signing_behavior" : "always",
#       "signing_protocol" : "sigv4"
#     }
#   }

  origin = {

    "${module.alb.dns_name}" = {
    domain_name      = "${module.alb.dns_name}"
    origin_type = "mediastore"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }
    # alb_oac = { # with origin access control settings (recommended)
    #   domain_name           = "${module.alb.dns_name}"
    #   origin_access_control = "alb_oac" # key in `origin_access_control`
    #     }


  }


  default_cache_behavior = {
    # path_pattern = "/*"

    target_origin_id       = "${module.alb.dns_name}"
    viewer_protocol_policy = "allow-all"

    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    query_string           = true
  }

}

