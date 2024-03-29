# errors, duration triggers, dead letter queues?
resource "azurerm_application_insights" "insights" {
  name                 = lower(format("%s-appi-%s", var.azure_name_prefix, var.azure_short_name))
  location             = var.azure_resource_group.location
  resource_group_name  = var.azure_resource_group.name
  application_type     = "web"
  daily_data_cap_in_gb = 1
  retention_in_days    = 90

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "exceptions" {
  name                = format("%s-exceptions", var.azure_short_name)
  resource_group_name = var.azure_resource_group.name
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
    for_each = var.azure_monitor_action_group_id == "" ? [] : [1]
    
    content {
      action_group_id = var.azure_monitor_action_group_id

      # data sent with the webhook
      webhook_properties = {
        "component" : var.azure_short_name
      }
    }
  }

  tags = var.tags

  # this custom metric is only created after the function app is created...
  depends_on = [azurerm_function_app.main]
}

resource "azurerm_application_insights_web_test" "ping" {
  name                    = lower(format("%s-appi-%s-ping", var.azure_name_prefix, var.azure_short_name))
  location                = var.azure_resource_group.location
  resource_group_name     = var.azure_resource_group.name
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
    <Request Method="GET" Version="1.1" Url="https://${azurerm_function_app.main.name}.azurewebsites.net/ct_api_extension/healthchecks?code=${var.azure_short_name}" ThinkTime="0" Timeout="300" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
  </Items>
</WebTest>
XML
}


resource "azurerm_monitor_metric_alert" "ping" {
  name                = format("%s-ping-response", var.azure_short_name)
  resource_group_name = var.azure_resource_group.name
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
    for_each = var.azure_monitor_action_group_id == "" ? [] : [1]
    content {
      action_group_id = var.azure_monitor_action_group_id

      # data sent with the webhook
      webhook_properties = {
        "component" : var.azure_short_name
      }
    }
  }

  tags = var.tags

  # this custom metric is only created after the function app is created...
  depends_on = [azurerm_function_app.main]
}

esource "azurerm_monitor_metric_alert" "topic_order_signals_dlq" {
  name                = format("%s-topic-order-signals-dlq", var.azure_short_name)
  resource_group_name = var.azure_resource_group.name
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
    for_each = var.azure_monitor_action_group_id == "" ? [] : [1]

    content {
      action_group_id = var.azure_monitor_action_group_id

      # data sent with the webhook
      webhook_properties = {
        "component" : var.azure_short_name
      }
    }
  }

  tags = var.tags
}

# Double since the previous alert doesn't seem to work reliably, hopefully this will always work
resource "azurerm_monitor_metric_alert" "dlq_files_exist" {
  name                = format("%s-sa-dlq-files-exist", var.azure_short_name)
  resource_group_name = var.azure_resource_group.name
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
    for_each = var.azure_monitor_action_group_id == "" ? [] : [1]

    content {
      action_group_id = var.azure_monitor_action_group_id

      # data sent with the webhook
      webhook_properties = {
        "component" : var.azure_short_name
      }
    }
  }

  tags = var.tags
}

resource "commercetools_api_client" "main" {
  name  = "${var.azure_name_prefix}_unit-test"
  scope = local.ct_scopes
}

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
}

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
}

locals {
  subscription_name     = format("%s-eg-%s-os-sub", var.azure_name_prefix, var.azure_short_name)
  event_grid_topic_name = format("%s-eg-%s-os-topic", var.azure_name_prefix, var.azure_short_name)
}

resource "azurerm_template_deployment" "ct_signals" {
  name                = local.event_grid_topic_name
  resource_group_name = var.azure_resource_group.name
  template_body       = file(format("%s/templates/eventgrid-topic.json", path.module))
  deployment_mode     = "Incremental"

  parameters = {
    "eventGridTopicName" = local.event_grid_topic_name
  }
}

data "azurerm_eventgrid_topic" "ct_signals" {
  name                = local.event_grid_topic_name
  resource_group_name = var.azure_resource_group.name

  depends_on = [
    azurerm_template_deployment.ct_signals,
  ]
}

data "azurerm_function_app_host_keys" "main" {
  name                = azurerm_function_app.main.name
  resource_group_name = var.azure_resource_group.name

  depends_on = [
    azurerm_function_app.main
  ]
}

resource "azurerm_template_deployment" "ct_signals_subscription" {
  name                = local.subscription_name
  resource_group_name = var.azure_resource_group.name
  template_body       = file(format("%s/templates/eventgrid-subscription.json", path.module))
  deployment_mode     = "Incremental"

  parameters = {
    "subscriptionName"      = local.subscription_name
    "eventGridTopicName"    = data.azurerm_eventgrid_topic.ct_signals.name
    "resourceGroupName"     = var.azure_resource_group.name
    "subscriptionId"        = var.azure_subscription_id
    "location"              = var.azure_resource_group.location
    "webhookUrl"            = format("https://%s/%s?code=%s", azurerm_function_app.main.default_hostname, "ct_subscription", data.azurerm_function_app_host_keys.main.default_function_key)
    "maxDeliveryAttempts"   = "10"
    "dlqContainerName"      = azurerm_storage_container.container_dlq.name
    "dlqStorageAccountName" = azurerm_storage_account.dlq.name
  }
}

data "azurerm_storage_account" "shared" {
  name                = ""
  resource_group_name = ""
}

data "azurerm_storage_container" "code" {
  name                 = "code"
  storage_account_name = data.azurerm_storage_account.shared.name
}


data "azurerm_app_service_plan" "main" {
  name                = var.azure_app_service_plan.name
  resource_group_name = var.azure_app_service_plan.resource_group_name
}

data "azurerm_storage_account_blob_container_sas" "code_access" {
  connection_string = data.azurerm_storage_account.shared.primary_connection_string
  container_name    = data.azurerm_storage_container.code.name
  https_only        = false
  start             = "2018-03-21"
  expiry            = "2028-03-21"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

locals {
  package_name = "${local.component_name}-${var.component_version}.zip"
}

# Check if the version really exists
data "external" "package_exists" {
  program = ["bash", "-c", "${path.module}/scripts/blob_exists.sh ${data.azurerm_storage_account.shared.primary_access_key} ${data.azurerm_storage_account.shared.name} ${data.azurerm_storage_container.code.name} ${local.package_name}"]
}

locals {
  environment_variables = {
    # Function metadata
    NAME               = local.component_name
    COMPONENT_VERSION  = var.component_version
    SITE               = var.site
    REGION             = var.azure_region
    ENVIRONMENT        = var.environment
    RELEASE            = "${local.component_name}@${var.component_version}"
    
    # Commercetools
    CTP_PROJECT_KEY            = var.ct_project_key
    CTP_SCOPES                 = join(",", local.ct_scopes)
    CTP_API_URL                = var.ct_api_url
    CTP_AUTH_URL               = var.ct_auth_url
    CTP_CLIENT_ID              = commercetools_api_client.main.id

    # Azure deployment
    WEBSITE_RUN_FROM_PACKAGE       = "https://${data.azurerm_storage_account.shared.name}.blob.core.windows.net/${data.azurerm_storage_container.code.name}/${local.package_name}${data.azurerm_storage_account_blob_container_sas.code_access.sas}"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME       = "python"
    
  }

  # Secrets, have to manually build these urls to ensure the latest version is in the functionapp and not the initial value.
  secret_variables = { for k, v in azurerm_key_vault_secret.secrets : replace(k, "-", "_") => "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/${v.name}/${v.version})" }

  extra_secrets = {
    CTP_CLIENT_SECRET = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/${azurerm_key_vault_secret.ct_client_secret.name}/${azurerm_key_vault_secret.ct_client_secret.version})"
  }

  app_is_premium = contains(["ElasticPremium", "Premium", "PremiumV2"], data.azurerm_app_service_plan.main.sku[0].tier)
}

resource "azurerm_function_app" "main" {
  name                       = lower(format("%s-func-%s", var.azure_name_prefix, var.azure_short_name))
  location                   = var.azure_resource_group.location
  resource_group_name        = var.azure_resource_group.name
  app_service_plan_id        = var.azure_app_service_plan.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  app_settings               = merge(var.variables, local.environment_variables, local.secret_variables, local.extra_secrets)
  os_type                    = "linux"
  version                    = "~3"
  https_only                 = true

  site_config {
    linux_fx_version = "PYTHON|3.8"
    ftps_state                = "Disabled"
    pre_warmed_instance_count = local.app_is_premium ? 1 : 0

    cors {
      allowed_origins = ["*"]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [data.external.package_exists, azurerm_key_vault_secret.secrets]
}

# see https://docs.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies#trigger-syncing
# this updates the functionapp in case of any changes.
data "external" "sync_trigger" {
  program = [
    "bash", 
    "-c", 
    "az rest --method post --uri 'https://management.azure.com/subscriptions/${var.azure_subscription_id}/resourceGroups/${var.azure_resource_group.name}/providers/Microsoft.Web/sites/${azurerm_function_app.main.name}/syncfunctiontriggers?api-version=2016-08-01'"
  ]
}

resource "azurerm_key_vault" "main" {
  name                        = replace(format("%s-kv-%s", var.azure_name_prefix, var.azure_short_name), "-", "")
  location                    = var.azure_resource_group.location
  resource_group_name         = var.azure_resource_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"

  tags = var.tags
}


resource "azurerm_key_vault_access_policy" "service_access" {
  for_each = var.azure_service_object_ids
  
  key_vault_id = azurerm_key_vault.main.id
  tenant_id = var.azure_tenant_id
  object_id = each.value

  secret_permissions = [
    "get",
    "list",
    "set",
    "delete"
  ]
}

resource "azurerm_key_vault_access_policy" "function_app" {
  key_vault_id = azurerm_key_vault.main.id

  tenant_id = var.azure_tenant_id
  object_id = azurerm_function_app.main.identity.0.principal_id

  secret_permissions = [
    "get",
    "list",
    "set",
    "delete"
  ]
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name         = replace(each.key, "_", "-")
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_key_vault_access_policy.service_access,
  ]
}

resource "azurerm_key_vault_secret" "ct_client_secret" {
  name         = "ct-client-secret"
  value        = commercetools_api_client.main.secret
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags

  depends_on = [
    azurerm_key_vault_access_policy.service_access,
  ]
}

locals {
  storage_type     = var.environment == "production" ? "ZRS" : "LRS"
  ct_scopes = formatlist("%s:%s", [
    "manage_orders",
		"view_orders",
  ], var.ct_project_key)
  component_name       = "unit-test"
}

terraform {
  required_providers {
    commercetools = {
      source = "labd/commercetools"
    }
  }
}
output "app_service_name" {
  value       = azurerm_function_app.main.name
  description = "Function app name"
}



resource "azurerm_storage_account" "main" {
  name                     = replace(lower(format("%s-sa-%s", var.azure_name_prefix, var.azure_short_name)), "-", "")
  location                 = var.azure_resource_group.location
  resource_group_name      = var.azure_resource_group.name
  account_tier             = "Standard"
  account_replication_type = local.storage_type
  allow_blob_public_access = false
  
  tags = var.tags
}

resource "azurerm_storage_account" "dlq" {
  name                     = replace(lower(format("%s-sa-%s-dlq", var.azure_name_prefix, var.azure_short_name)), "-", "")
  location                 = var.azure_resource_group.location
  resource_group_name      = var.azure_resource_group.name
  account_tier             = "Standard"
  account_replication_type = local.storage_type
  allow_blob_public_access = false

  tags = var.tags
}

resource "azurerm_storage_container" "container_dlq" {
  name                  = "dlq"
  storage_account_name  = azurerm_storage_account.dlq.name
  container_access_type = "private"
}

variable "azure_short_name" {
  type        = string
  description = "Short name passed by MACH. Will not be more than 10 characters"
}

variable "azure_name_prefix" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_service_object_ids" {
  type        = map(string)
  default     = {}
  description = "Map of object ids that should have access to the keyvaults. (f.e. jenkins + developers)"
}

variable "azure_region" {
  type        = string
  default     = ""
  description = "Region: Azure region"
}

variable "azure_resource_group" {
  type = object({
    name     = string
    location = string
  })
  description = "Information of the resource group the component should be created in"
}

variable "azure_app_service_plan" {
  type = object({
    id                  = string
    name                = string
    resource_group_name = string
  })
}

variable "azure_monitor_action_group_id" {
  type        = string
  description = "Azure Monitor action group to send alerts to."
  default     = ""
}



variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`"
}

variable "component_version" {
  type        = string
  description = "Version to deploy"
}

variable "environment" {
  type        = string
  description = "Specify what environment it's in (e.g. `test` or `production`)"
}

variable "site" {
  type        = string
  description = "Identifier of the site."
}



variable "ct_project_key" {
  type = string
}

variable "ct_api_url" {
  type    = string
  default = ""
}

variable "ct_auth_url" {
  type    = string
  default = ""
}

variable "ct_stores" {
  type = map(object({
    key       = string
    variables = any
    secrets   = any
  }))
  default = {}
}

variable "variables" {
  type        = any
  description = "Generic way to pass variables to components. Some of these can also be used as environment variables."
}

variable "secrets" {
  type        = any
  description = "Map of secret values. Will be put in the key vault."
  default     = {}
}

