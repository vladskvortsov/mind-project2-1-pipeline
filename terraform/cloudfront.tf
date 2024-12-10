data "aws_caller_identity" "current" {}

module "cloudfront" {
  # depends_on = [module.s3_bucket]
  source = "terraform-aws-modules/cloudfront/aws"


  enabled             = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false
  default_root_object = "index.html"

  create_origin_access_control = true

  origin_access_control = {
    "s3_oac" : {
      "description" : "",
      "origin_type" : "s3",
      "signing_behavior" : "always",
      "signing_protocol" : "sigv4"
    }
  }

  origin = {


    "${var.frontend_bucket_name}.s3.amazonaws.com" = {
      domain_name           = "${var.frontend_bucket_name}.s3.amazonaws.com"
      origin_access_control = "s3_oac"

    }
  }

  default_cache_behavior = {
    path_pattern = "/*"

    target_origin_id       = "${var.frontend_bucket_name}.s3.amazonaws.com"
    viewer_protocol_policy = "allow-all"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

}

# resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
#   bucket = var.frontend_bucket_name
#   policy = <<EOF
#                     {
#                       "Version": "2008-10-17",
#                       "Id": "PolicyForCloudFrontPrivateContent",
#                       "Statement": [
#                           {
#                               "Sid": "AllowCloudFrontServicePrincipal",
#                               "Effect": "Allow",
#                               "Principal": {
#                                   "Service": "cloudfront.amazonaws.com"
#                               },
#                               "Action": "s3:GetObject",
#                               "Resource": "arn:aws:s3:::${var.frontend_bucket_name}/*",
#                               "Condition": {
#                                   "StringEquals": {
#                                       "AWS:SourceArn": "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.cloudfront.cloudfront_distribution_id}"
#                                   }
#                               }
#                           }
#                       ]
#                     }
#   EOF
# }