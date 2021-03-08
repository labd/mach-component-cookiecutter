resource "commercetools_api_client" "main" {
  name  = "${var.azure_name_prefix}_{{ cookiecutter.name|slugify }}"
  scope = local.ct_scopes
}

{% if cookiecutter.use_commercetools_subscription|int -%}
resource "commercetools_subscription" "main" {
  key = "${var.azure_name_prefix}_order_payed"

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
data "azurerm_function_app_host_keys" "function_keys" {
  name                = azurerm_function_app.main.name
  resource_group_name = var.azure_resource_group.name
  depends_on = [
    azurerm_function_app.main
  ]
}

locals {
  function_app_key = data.azurerm_function_app_host_keys.function_keys.default_function_key
}

resource "commercetools_api_extension" "main" {
  key = "create-order"

  destination = {
    type                 = "http"
    url                  = "https://${azurerm_function_app.main.name}.azurewebsites.net/ct_api_extension"
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
