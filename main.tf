terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0" # Updated to reflect current attribute syntax
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_account_id" {
  type = string
}

locals {
  route_data = jsondecode(file("${path.module}/routes.json"))
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "ecs_external_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = "faaebdd0-d62d-4ce2-b161-0f4508a56697"

  # In v5.x, 'config' is an attribute (=) and takes an object
  # Ingress rules are passed as a list of objects under the 'ingress' key
  config = {
    ingress = concat(
      [
        for route in local.route_data : {
          hostname = route.hostname
          service  = route.service
        }
      ],
      [
        {
          service = "http_status:404"
        }
      ]
    )
  }
}