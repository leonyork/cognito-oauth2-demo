variable "region" {
  default = "us-east-1"
}
variable "stage" {
  default = "dev"
}
variable "service" {
  default = "auth-demo"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_s3_bucket" "b" {
  bucket = "${var.stage}-${var.service}"
  acl    = "private"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_origin_access_identity" "default" {
  comment = "Origin Access Identity"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.b.bucket_regional_domain_name}"
    origin_id = "${local.s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path}"
    }
  }

  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }
  
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cognito_user_pool" "pool" {
  name = "${var.stage}-${var.service}"
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]
  password_policy = {
    minimum_length = 6
    require_symbols = false
    require_uppercase = false
  }
}
resource "aws_cognito_user_pool_client" "client" {
  name = "${var.stage}-${var.service}"
  user_pool_id = "${aws_cognito_user_pool.pool.id}"
  generate_secret = false
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH"]
  supported_identity_providers = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["implicit"]
  allowed_oauth_scopes = ["openid"]
  callback_urls = ["https://${aws_cloudfront_distribution.s3_distribution.domain_name}/"]
  logout_urls = ["https://${aws_cloudfront_distribution.s3_distribution.domain_name}/"]
}

resource "aws_cognito_user_pool_domain" "pool-domain" {
  domain = "${var.stage}-${var.service}"
  user_pool_id = "${aws_cognito_user_pool.pool.id}"
}
resource "null_resource" "build-and-deploy-back-end" {
  depends_on = ["aws_cognito_user_pool_domain.pool-domain","aws_cognito_user_pool_client.client","aws_cognito_user_pool.pool","aws_cloudfront_distribution.s3_distribution", "aws_cloudfront_origin_access_identity.default", "aws_s3_bucket.b"]

  #Ensure we run this build and deploy every time - even if the other resources didn't need to be changed - This is a known hack - see https://www.kecklers.com/terraform-null-resource-execute-every-time/ and https://github.com/hashicorp/terraform/pull/3244
  triggers {
      build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOF
    cd user-store-api-secured && \
    USER_STORE_API_SECURED_ISSUER=https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.pool.id} \
    USER_STORE_API_ACCESS_CONTROL_ALLOW_ORIGIN=https://${aws_cloudfront_distribution.s3_distribution.domain_name} \
    npm run deploy
    EOF
  }
}
resource "null_resource" "build-and-deploy-front-end" {
  depends_on = ["null_resource.build-and-deploy-back-end"]

  #Ensure we run this build and deploy every time - even if the other resources didn't need to be changed - This is a known hack - see https://www.kecklers.com/terraform-null-resource-execute-every-time/ and https://github.com/hashicorp/terraform/pull/3244
  triggers {
      build_number = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOF
    VUE_APP_COGNITO_HOST=${var.stage}-${var.service}.auth.${var.region}.amazoncognito.com \
    VUE_APP_CLIENT_ID=${aws_cognito_user_pool_client.client.id} \
    VUE_APP_REDIRECT_URL=https://${aws_cloudfront_distribution.s3_distribution.domain_name}/ \
    npm run build && \
    aws s3 sync dist s3://${var.stage}-${var.service} --acl public-read --region=${var.region} && \
    aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.s3_distribution.id} --paths /index.html --region=${var.region}
    EOF
  }
}
output "user-pool-id" {
  value = "${aws_cognito_user_pool.pool.id}"
}
output "user-pool-client-id" {
  value = "${aws_cognito_user_pool_client.client.id}"
}
output "cloudfront-domain-name" {
  value = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
}
output "token-issuer" {
  value = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.pool.id}"
}
output "user-endpoint" {
  value = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}/"
}