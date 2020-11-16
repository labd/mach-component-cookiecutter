locals {
  ct_scopes = formatlist("%s:%s", [
    "manage_orders",
  ], var.ct_project_key)
}

resource "commercetools_api_client" "main" {
  name  = format("%s_{{ cookiecutter.name|slugify }}", var.name_prefix)
  scope = local.ct_scopes
}