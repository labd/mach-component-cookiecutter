resource "commercetools_api_client" "main" {
  name  = "${var.name_prefix}_{{ cookiecutter.name|slugify }}"
  scope = local.ct_scopes
}

{% if cookiecutter.use_commercetools_subscription|int -%}
resource "commercetools_subscription" "main" {
  key = "${var.name_prefix}_order_payed"

  destination = {
    type       = "azure_eventgrid"
    uri        = data.azurerm_eventgrid_topic.ct_signals.endpoint
    access_key = data.azurerm_eventgrid_topic.ct_signals.primary_access_key
  }

  changes {
    resource_type_ids = ["order"]
  }

  message {
    resource_type_id = "order"
    types            = ["OrderCreated", "OrderPaymentStateChanged"]
  }

  format = {
    type                 = "cloud_events"
    cloud_events_version = "1.0"
  }
}{% endif %}

{% if cookiecutter.use_commercetools_api_extension|int -%}
# Get the functions keys out of the app
resource "azurerm_template_deployment" "function_keys" {
  name = "${azurerm_function_app.main.name}-function-keys"
  parameters = {
    "functionApp" = azurerm_function_app.main.name
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

resource "commercetools_api_extension" "main" {
  key = "create-order"

  destination = {
    type                 = "http"
    url                  = "https://${azurerm_function_app.main.name}.azurewebsites.net/ct_subscription"
    azure_authentication = local.function_app_key
  }

  trigger {
    resource_type_id = "order"
    actions          = ["Create"]
  }

  depends_on = [
    azurerm_function_app.main
  ]
}{% endif %}