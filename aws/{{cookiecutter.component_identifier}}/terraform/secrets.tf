locals {
  {% if cookiecutter.use_commercetools|int and cookiecutter.use_commercetools_token_rotator|int -%}
  secrets = var.secrets
  secret_references = merge({
    for key in keys(local.secrets) : "${key}_SECRET_NAME" => aws_secretsmanager_secret.component_secret[key].name
  }, {
    CT_ACCESS_TOKEN_SECRET_NAME = module.ct_secret.name
  }){% else -%}
  secrets = merge(var.secrets, {
    {% if cookiecutter.use_commercetools|int -%}
    CT_CLIENT_SECRET = commercetools_api_client.main.secret,{% endif %}
  })
  secret_references = {
    for key in keys(local.secrets) : "${key}_SECRET_NAME" => aws_secretsmanager_secret.component_secret[key].name
  }{% endif %}
}

resource "random_id" "main" {
  byte_length = 5
  keepers = {
    # Generate a new id each time set of secrets change
    secrets = join("", tolist(keys(local.secrets)))
  }
}

resource "aws_secretsmanager_secret" "component_secret" {
  for_each = local.secrets
  name     = "${local.component_name}/${replace(each.key, "_", "-")}-secret-${random_id.main.hex}"

  tags = {
    lambda = local.component_name
  }
}

resource "aws_secretsmanager_secret_version" "component_secret" {
  for_each      = local.secrets
  secret_id     = aws_secretsmanager_secret.component_secret[each.key].id
  secret_string = each.value
}

{% if cookiecutter.use_commercetools|int and cookiecutter.use_commercetools_token_rotator|int -%}
module "ct_secret" {
  source = "git::https://github.com/labd/mach-component-aws-commercetools-token-refresher.git//terraform/secret"

  name   = local.component_name
  site   = var.site
  scopes = local.ct_scopes
}{% endif %}