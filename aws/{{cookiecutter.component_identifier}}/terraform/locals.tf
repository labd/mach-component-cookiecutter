locals {
  {% if cookiecutter.use_commercetools|int -%}
  ct_scopes = formatlist("%s:%s", [
    "manage_orders",
    "view_orders",
  ], var.ct_project_key)
  {%- endif %}
  component_name       = "{{ cookiecutter.name|slugify }}"
  lambda_s3_repository = "{{ cookiecutter.lambda_s3_repository }}"
  lambda_s3_key        = "${local.component_name}-${var.component_version}.zip"
}
