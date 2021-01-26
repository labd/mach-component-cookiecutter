# errors, duration triggers, dead letter queues?
resource "azurerm_application_insights" "insights" {
  name                 = lower(format("%s-appi-%s", var.name_prefix, var.short_name))
  location             = var.resource_group_location
  resource_group_name  = var.resource_group_name
  application_type     = "web"
  daily_data_cap_in_gb = 1
  retention_in_days    = 90

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "exceptions" {
  name                = format("%s-exceptions", var.short_name)
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_insights.insights.id]
  description         = "Action will be triggered when uncaught exceptions are present"

  frequency   = "PT5M"
  window_size = "PT5M"
  severity    = 2

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "exceptions/count"
    aggregation      = "Count"
    operator         = "GreaterThanOrEqual"
    threshold        = 0.9
  }

  dynamic "action" {
    for_each = var.monitor_action_group_id == "" ? [] : [1]
    
    content {
      action_group_id = var.monitor_action_group_id

      # data sent with the webhook
      webhook_properties = {
        "component" : var.short_name
      }
    }
  }

  tags = var.tags

  # this custom metric is only created after the function app is created...
  depends_on = [azurerm_function_app.main]
}

{% if cookiecutter.use_commercetools_api_extension|int or cookiecutter.use_public_api|int -%}
resource "azurerm_application_insights_web_test" "ping" {
  name                    = lower(format("%s-appi-%s-ping", var.name_prefix, var.short_name))
  location                = var.resource_group_location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.insights.id
  kind                    = "ping"
  frequency               = 300
  timeout                 = 60
  enabled                 = true
  geo_locations = [
    "emea-nl-ams-azr",
    "emea-se-sto-edge",
    "emea-ru-msa-edge",
  ]

  tags = var.tags

  configuration = <<XML
<WebTest Name="PingTest" Enabled="True" Timeout="0" Proxy="default" StopOnError="False" RecordedResultFile="">
  <Items>
    <Request Method="GET" Version="1.1" Url="https://${azurerm_function_app.main.name}.azurewebsites.net/ct_api_extension/healthchecks?code=${var.short_name}" ThinkTime="0" Timeout="300" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
  </Items>
</WebTest>
XML
}


resource "azurerm_monitor_metric_alert" "ping" {
  name                = format("%s-ping-response", var.short_name)
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_insights.insights.id]
  description         = "Action will be triggered when ping response is too long"

  frequency   = "PT5M"
  window_size = "PT5M"
  severity    = 3

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "availabilityresults/duration"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  dynamic "action" {
    for_each = var.monitor_action_group_id == "" ? [] : [1]
    content {
      action_group_id = var.monitor_action_group_id

      # data sent with the webhook
      webhook_properties = {
        "component" : var.short_name
      }
    }
  }

  tags = var.tags

  # this custom metric is only created after the function app is created...
  depends_on = [azurerm_function_app.main]
}{% endif %}

{% if cookiecutter.use_commercetools_subscription|int -%}
esource "azurerm_monitor_metric_alert" "topic_order_signals_dlq" {
  name                = format("%s-topic-order-signals-dlq", var.short_name)
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_eventgrid_topic.ct_signals.id]
  description         = "Action will be triggered when topic messages are deadlettered."

  frequency   = "PT5M"
  window_size = "PT5M"
  severity    = 2

  criteria {
    metric_namespace = "Microsoft.EventGrid/topics"
    metric_name      = "DeadLetteredCount"
    aggregation      = "Total"
    operator         = "GreaterThanOrEqual"
    threshold        = 0.9
    dimension {
      name     = "DeadLetterReason"
      operator = "Include"
      values   = ["MaxDeliveryAttemptsExceeded"]
    }
  }

  dynamic "action" {
    for_each = var.monitor_action_group_id == "" ? [] : [1]

    content {
      action_group_id = var.monitor_action_group_id

      # data sent with the webhook
      webhook_properties = {
        "component" : var.short_name
      }
    }
  }

  tags = var.tags
}

# Double since the previous alert doesn't seem to work reliably, hopefully this will always work
resource "azurerm_monitor_metric_alert" "dlq_files_exist" {
  name                = format("%s-sa-dlq-files-exist", var.short_name)
  resource_group_name = var.resource_group_name
  scopes              = [format("%s/blobServices/default", azurerm_storage_account.dlq.id)]
  description         = "Action will be triggered when DLQ files exist."

  frequency   = "PT1M"
  window_size = "PT1H"
  severity    = 2

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts/blobServices"
    metric_name      = "BlobCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0.0
  }

  dynamic "action" {
    for_each = var.monitor_action_group_id == "" ? [] : [1]

    content {
      action_group_id = var.monitor_action_group_id

      # data sent with the webhook
      webhook_properties = {
        "component" : var.short_name
      }
    }
  }

  tags = var.tags
}{% endif %}