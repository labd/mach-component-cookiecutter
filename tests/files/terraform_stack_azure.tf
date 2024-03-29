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
    
    

    # Azure deployment
    WEBSITE_RUN_FROM_PACKAGE       = "https://${data.azurerm_storage_account.shared.name}.blob.core.windows.net/${data.azurerm_storage_container.code.name}/${local.package_name}${data.azurerm_storage_account_blob_container_sas.code_access.sas}"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME       = "python"
    
  }

  # Secrets, have to manually build these urls to ensure the latest version is in the functionapp and not the initial value.
  secret_variables = { for k, v in azurerm_key_vault_secret.secrets : replace(k, "-", "_") => "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/${v.name}/${v.version})" }

  extra_secrets = {
    
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



locals {
  storage_type     = var.environment == "production" ? "ZRS" : "LRS"
  
  component_name       = "unit-test"
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





variable "variables" {
  type        = any
  description = "Generic way to pass variables to components. Some of these can also be used as environment variables."
}

variable "secrets" {
  type        = any
  description = "Map of secret values. Will be put in the key vault."
  default     = {}
}

