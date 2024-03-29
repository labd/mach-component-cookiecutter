data "azurerm_storage_account" "shared" {
  name                = "{{ cookiecutter.function_storage_account }}"
  resource_group_name = "{{ cookiecutter.shared_resource_group }}"
}

data "azurerm_storage_container" "code" {
  name                 = "{{ cookiecutter.function_container_name }}"
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
    
    {% if cookiecutter.use_commercetools|int -%}
    # Commercetools
    CTP_PROJECT_KEY            = var.ct_project_key
    CTP_SCOPES                 = join(",", local.ct_scopes)
    CTP_API_URL                = var.ct_api_url
    CTP_AUTH_URL               = var.ct_auth_url
    CTP_CLIENT_ID              = commercetools_api_client.main.id{% endif %}

    # Azure deployment
    WEBSITE_RUN_FROM_PACKAGE       = "https://${data.azurerm_storage_account.shared.name}.blob.core.windows.net/${data.azurerm_storage_container.code.name}/${local.package_name}${data.azurerm_storage_account_blob_container_sas.code_access.sas}"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME       = "{{ cookiecutter.language }}"
    {% if cookiecutter.use_public_api|int %}
    FRONTDOOR_ID = var.azure_endpoint_main.frontdoor_id
    {% endif %}
  }

  # Secrets, have to manually build these urls to ensure the latest version is in the functionapp and not the initial value.
  secret_variables = { for k, v in azurerm_key_vault_secret.secrets : replace(k, "-", "_") => "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/${v.name}/${v.version})" }

  extra_secrets = {
    {% if cookiecutter.use_commercetools|int -%}
    CTP_CLIENT_SECRET = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/${azurerm_key_vault_secret.ct_client_secret.name}/${azurerm_key_vault_secret.ct_client_secret.version})"{% endif %}
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
    {% if cookiecutter.language == "node" -%}
    linux_fx_version = "NODE|10.15"{% elif cookiecutter.language == "python" -%}
    linux_fx_version = "PYTHON|3.8"{% endif %}
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
