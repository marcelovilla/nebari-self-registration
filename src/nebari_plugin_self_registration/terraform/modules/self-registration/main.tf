locals {

  # TODO: temporary image until MetroStar GH package is public.
  image_name = "docker.io/kennethfoster/nebari-self-registration"
  image_tag  = "latest"

}

resource "kubernetes_namespace" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "helm_release" "self_registration" {
  name      = var.chart_name
  chart     = "${path.module}/chart"
  namespace = var.create_namespace ? kubernetes_namespace.this[0].metadata[0].name : var.namespace

  values = [
    yamlencode({
      logLevel = "info"
      timeout  = "3600"
      ingress = {
        enabled = "true"
        host    = var.ingress_host
      }
      keycloak = {
        secret = {
          data = {
            client_id     = var.keycloak_config["client_id"]
            client_secret = var.keycloak_config["client_secret"]
            signing_key   = var.keycloak_config["signing_key"]

            issuer_url    = var.keycloak_config["issuer_url"]
            discovery_url = var.keycloak_config["discovery_url"]
            auth_url      = var.keycloak_config["auth_url"]
            token_url     = var.keycloak_config["token_url"]
            jwks_url      = var.keycloak_config["jwks_url"]
            logout_url    = var.keycloak_config["logout_url"]
            userinfo_url  = var.keycloak_config["userinfo_url"]
          }
        }
      }
      image = {
        repository = local.image_name
        tag        = local.image_tag
      }
      serviceAccount = {
        name = var.self_registration_sa_name
      }
      app_configuration = {
        coupons = ["COUPON1"]
        approved_domains = ["gmail.com"]
        account_expiration_days = "7"
        keycloak = {
          server_url: "https://nebari.kflabs.click/auth"
          realm_name: "nebari"
          client_id: "self-registration"
          client_secret: "746827e0-6408-41db-a0b7-174444912282"
        }
      }
      env = [
      ]
    }),
    yamlencode(var.overrides),
  ]
}