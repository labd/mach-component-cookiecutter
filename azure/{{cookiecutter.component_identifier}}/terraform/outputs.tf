output "app_service_name" {
  value       = azurerm_function_app.main.name
  description = "Function app name"
}

{% if cookiecutter.use_public_api|int %}
output "azure_endpoint_main" {
  value = {
    address = azurerm_function_app.main.default_hostname
  }
}
{% endif %}
