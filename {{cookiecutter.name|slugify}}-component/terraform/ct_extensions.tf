resource "commercetools_api_client" "{{ cookiecutter.component_identifier }}" {
  name  = format("%s_{{ cookiecutter.component_identifier }}", var.name_prefix)
  scope = local.ct_scopes
}

data "azurerm_resource_group" "current" {
  name = var.resource_group_name
}


resource "commercetools_api_extension" "cart_actions" {
  key = "create-cart"

  destination = {
    type                 = "http"
    url                  = "https://${azurerm_function_app.{{ cookiecutter.component_identifier }}.name}.azurewebsites.net/{{ cookiecutter.function_name }}"
    azure_authentication = local.function_app_key
  }

  trigger {
    resource_type_id = "cart"
    actions          = ["Create"]
  }

  trigger {
    resource_type_id = "order"
    actions          = ["Create"]
  }

  depends_on = [
    azurerm_function_app.{{ cookiecutter.component_identifier }}
  ]
}
