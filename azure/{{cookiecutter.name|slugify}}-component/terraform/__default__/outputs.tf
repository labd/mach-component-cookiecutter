output "app_service_name" {
  value       = azurerm_function_app.{{ cookiecutter.component_identifier }}.name
  description = "Function app name"
}

output "app_service_url" {
  value       = azurerm_function_app.{{ cookiecutter.component_identifier }}.default_hostname
  description = "Function app service url"
}
