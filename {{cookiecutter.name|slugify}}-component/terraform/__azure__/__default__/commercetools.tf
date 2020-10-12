locals {
  ct_scopes = formatlist("%s:%s", [
    "manage_orders",
  ], var.ct_project_key)
}

resource "commercetools_api_client" "{{ cookiecutter.component_identifier }}" {
  name  = format("%s_{{ cookiecutter.component_identifier }}", var.name_prefix)
  scope = local.ct_scopes
}