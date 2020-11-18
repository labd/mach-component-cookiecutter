locals {
  subscription_name     = format("%s-eg-%s-os-sub", var.name_prefix, var.short_name)
  event_grid_topic_name = format("%s-eg-%s-os-topic", var.name_prefix, var.short_name)
}

resource "azurerm_template_deployment" "ct_signals" {
  name                = local.event_grid_topic_name
  resource_group_name = var.resource_group_name
  template_body       = file(format("%s/templates/eventgrid-topic.json", path.module))
  deployment_mode     = "Incremental"

  parameters = {
    "eventGridTopicName" = local.event_grid_topic_name
  }
}

data "azurerm_eventgrid_topic" "ct_signals" {
  name                = local.event_grid_topic_name
  resource_group_name = var.resource_group_name

  depends_on = [
    azurerm_template_deployment.ct_signals,
  ]
}

data "azurerm_function_app_host_keys" "main" {
  name                = azurerm_function_app.main.name
  resource_group_name = var.resource_group_name

  depends_on = [
    azurerm_function_app.main
  ]
}

resource "azurerm_template_deployment" "ct_signals_subscription" {
  name                = local.subscription_name
  resource_group_name = var.resource_group_name
  template_body       = file(format("%s/templates/eventgrid-subscription.json", path.module))
  deployment_mode     = "Incremental"

  parameters = {
    "subscriptionName"      = local.subscription_name
    "eventGridTopicName"    = data.azurerm_eventgrid_topic.ct_signals.name
    "resourceGroupName"     = var.resource_group_name
    "subscriptionId"        = var.subscription_id
    "location"              = var.resource_group_location
    "webhookUrl"            = format("https://%s/%s?code=%s", azurerm_function_app.main.default_hostname, "ct_subscription", data.azurerm_function_app_host_keys.main.default_function_key)
    "maxDeliveryAttempts"   = "10"
    "dlqContainerName"      = azurerm_storage_container.container_dlq.name
    "dlqStorageAccountName" = azurerm_storage_account.dlq.name
  }
}
