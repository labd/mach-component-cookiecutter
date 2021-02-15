locals {
  storage_type     = var.environment == "production" ? "ZRS" : "LRS"
  {% if cookiecutter.use_commercetools|int -%}
  ct_scopes = formatlist("%s:%s", [
    "manage_orders",
		"view_orders",
  ], var.ct_project_key){% endif %}
  component_name       = "{{ cookiecutter.name|slugify }}"
}
