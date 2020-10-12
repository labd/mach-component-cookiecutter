locals {
  ct_scopes = formatlist("%s:%s", [
    "manage_orders",
  ], var.ct_project_key)
}

resource "commercetools_api_client" "{{ cookiecutter.component_identifier }}" {
  name  = format("%s_{{ cookiecutter.component_identifier }}", var.name_prefix)
  scope = local.ct_scopes
}

# Get the functions keys out of the app
resource "azurerm_template_deployment" "function_keys" {
  name = "${azurerm_function_app.{{ cookiecutter.component_identifier }}.name}-function-keys"
  parameters = {
    "functionApp" = azurerm_function_app.{{ cookiecutter.component_identifier }}.name
  }
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"

  template_body = <<BODY
  {
      "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
      "contentVersion": "1.0.0.0",
      "parameters": {
          "functionApp": {"type": "string", "defaultValue": ""}
      },
      "variables": {
          "functionAppId": "[resourceId('Microsoft.Web/sites', parameters('functionApp'))]"
      },
      "resources": [
      ],
      "outputs": {
          "functionkey": {
              "type": "string",
              "value": "[listkeys(concat(variables('functionAppId'), '/host/default'), '2018-11-01').functionKeys.default]"                                                                                }
      }
  }
  BODY
}

locals {
  function_app_key = lookup(azurerm_template_deployment.function_keys.outputs, "functionkey")
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
