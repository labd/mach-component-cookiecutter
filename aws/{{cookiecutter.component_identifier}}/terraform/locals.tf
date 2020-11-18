locals {
  ct_scopes = formatlist("%s:%s", [
    "manage_orders",
    "view_orders",
  ], var.ct_project_key)
  lambda_s3_repository = "{{ cookiecutter.lambda_s3_repository }}"
  lambda_s3_key        = "{{ cookiecutter.name|replace('_', '-') }}-${var.component_version}.zip"
}
