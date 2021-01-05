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
    <Request Method="GET" Version="1.1" Url="https://${azurerm_function_app.main.name}.azurewebsites.net/unit_test/healthchecks?code=${var.short_name}" ThinkTime="0" Timeout="300" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
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
}


data "azurerm_storage_account" "shared" {
  name                = ""
  resource_group_name = ""
}

data "azurerm_storage_container" "code" {
  name                 = "code"
  storage_account_name = data.azurerm_storage_account.shared.name
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
  package_name = format("unittest-%s.zip", var.component_version)
}

# Check if the version really exists
data "external" "package_exists" {
  program = ["bash", "-c", "${path.module}/scripts/blob_exists.sh ${data.azurerm_storage_account.shared.primary_access_key} ${data.azurerm_storage_account.shared.name} ${data.azurerm_storage_container.code.name} ${local.package_name}"]
}

locals {
  environment_variables = {
    # Function metadata
    NAME               = var.short_name
    COMPONENT_VERSION  = var.component_version
    SITE               = var.site
    REGION             = var.region
    ENVIRONMENT        = var.environment
    

    # Azure deployment
    # Note: WEBSITE_RUN_FROM_ZIP is needed for consumption plan, but for app service plan this may need to be WEBSITE_RUN_FROM_PACKAGE instead.
    WEBSITE_RUN_FROM_ZIP           = "https://${data.azurerm_storage_account.shared.name}.blob.core.windows.net/${data.azurerm_storage_container.code.name}/${local.package_name}${data.azurerm_storage_account_blob_container_sas.code_access.sas}"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME       = "python"
  }

  # Secrets, have to manually build these urls to ensure the latest version is in the functionapp and not the initial value.
  secret_variables = { for k, v in azurerm_key_vault_secret.secrets : replace(k, "-", "_") => "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/${v.name}/${v.version})" }

  extra_secrets = {
    
  }
}

resource "azurerm_function_app" "main" {
  name                       = lower(format("%s-func-%s", var.name_prefix, var.short_name))
  location                   = var.resource_group_location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = var.app_service_plan_id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  app_settings               = merge(var.variables, local.environment_variables, local.secret_variables, local.extra_secrets)
  os_type                    = "linux"
  version                    = "~3"
  https_only                 = true

  site_config {
    linux_fx_version = "PYTHON|3.8"

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
resource "azurerm_key_vault" "main" {
  name                        = replace(format("%s-kv-%s", var.name_prefix, var.short_name), "-", "")
  location                    = var.resource_group_location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"

  tags = var.tags
}


resource "azurerm_key_vault_access_policy" "service_access" {
  for_each = var.service_object_ids
  
  key_vault_id = azurerm_key_vault.main.id
  tenant_id = var.tenant_id
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

  tenant_id = var.tenant_id
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


locals {
  storage_type     = var.environment == "production" ? "ZRS" : "LRS"
  
}


output "app_service_name" {
  value       = azurerm_function_app.main.name
  description = "Function app name"
}

output "app_service_url" {
  value       = azurerm_function_app.main.default_hostname
  description = "Function app service url"
}

resource "azurerm_storage_account" "main" {
  name                     = replace(lower(format("%s-sa-%s", var.name_prefix, var.short_name)), "-", "")
  location                 = var.resource_group_location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = local.storage_type
  allow_blob_public_access = false
  
  tags = var.tags
}


variable "short_name" {
  type        = string
  description = "Short name passed by Mull. Will not be more than 10 characters"
}

variable "name_prefix" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "service_object_ids" {
  type        = map(string)
  default     = {}
  description = "Map of object ids that should have access to the keyvaults. (f.e. jenkins + developers)"
}

variable "region" {
  type        = string
  default     = ""
  description = "Region: Azure region"
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "app_service_plan_id" {
  type = string
}

variable "monitor_action_group_id" {
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



variable "variables" {
  type        = map(string)
  description = "Generic way to pass variables to components. Some of these can also be used as environment variables."
}

variable "secrets" {
  type        = map(string)
  description = "Map of secret values. Will be put in the key vault."
  default     = {}
}
