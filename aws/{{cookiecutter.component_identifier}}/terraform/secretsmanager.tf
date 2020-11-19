resource "aws_secretsmanager_secret" "custom_secrets" {
  name = "{{ cookiecutter.name | slugify }}/custom-secrets"
}

locals {
  custom_secrets = {
    REST_API_BASIC_AUTH_USERNAME = lookup(var.secrets, "REST_API_BASIC_AUTH_USERNAME", "")
    REST_API_BASIC_AUTH_PASSWORD = lookup(var.secrets, "REST_API_BASIC_AUTH_PASSWORD", "")
    STRIPE_API_KEY               = lookup(var.secrets, "STRIPE_API_KEY", "")
  }
}

resource "aws_secretsmanager_secret_version" "custom_secrets" {
  secret_id     = aws_secretsmanager_secret.custom_secrets.id
  secret_string = jsonencode(local.custom_secrets)
}
