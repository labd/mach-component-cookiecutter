resource "commercetools_api_client" "{{ cookiecutter.component_identifier }}" {
  name  = format("%s_{{ cookiecutter.component_identifier }}", var.name_prefix)
  scope = local.ct_scopes
}

resource "commercetools_api_extension" "order_actions" {
  key = "create-order"

  destination = {
    type                 = "http"
    url                  = "https://${azurerm_function_app.{{ cookiecutter.component_identifier }}.name}.azurewebsites.net/{{ cookiecutter.function_name }}"
    azure_authentication = local.function_app_key
  }

  trigger {
    resource_type_id = "order"
    actions          = ["Create"]
  }

  depends_on = [
    azurerm_function_app.{{ cookiecutter.component_identifier }}
  ]
}
