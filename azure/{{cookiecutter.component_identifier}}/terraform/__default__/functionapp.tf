data "azurerm_storage_account" "shared" {
  name                = "{{ cookiecutter.function_storage_account }}"
  resource_group_name = "{{ cookiecutter.shared_resource_group }}"
}

data "azurerm_storage_container" "code" {
  name                 = "{{ cookiecutter.function_container_name }}"
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
  package_name = format("{{ cookiecutter.short_name }}-%s.zip", var.component_version)
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
    
    # Commercetools
    CTP_PROJECT_KEY            = var.variables["CT_PROJECT_KEY"]
    CTP_SCOPES                 = join(",", local.ct_scopes)
    CTP_API_URL                = var.variables["CT_API_URL"]
    CTP_AUTH_URL               = var.variables["CT_AUTH_URL"]
    CTP_CLIENT_ID              = commercetools_api_client.main.id


    # Azure deployment
    # Note: WEBSITE_RUN_FROM_ZIP is needed for consumption plan, but for app service plan this may need to be WEBSITE_RUN_FROM_PACKAGE instead.
    WEBSITE_RUN_FROM_ZIP           = "https://${data.azurerm_storage_account.shared.name}.blob.core.windows.net/${data.azurerm_storage_container.code.name}/${local.package_name}${data.azurerm_storage_account_blob_container_sas.code_access.sas}"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME       = "{{ cookiecutter.language }}"
  }

  # Secrets, have to manually build these urls to ensure the latest version is in the functionapp and not the initial value.
  secret_variables = { for k, v in azurerm_key_vault_secret.secrets : replace(k, "-", "_") => "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/${v.name}/${v.version})" }

  extra_secrets = {
    CTP_CLIENT_SECRET = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/${azurerm_key_vault_secret.ct_client_secret.name}/${azurerm_key_vault_secret.ct_client_secret.version})"
  }
}

resource "azurerm_function_app" "main2" {
  name                       = lower(format("%s-func-%s", var.name_prefix, var.short_name))
  location                   = var.resource_group_location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = var.app_service_plan_id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  app_settings               = merge(var.environment_variables, local.environment_variables, local.secret_variables, local.extra_secrets)
  os_type                    = "linux"
  version                    = "~3"
  https_only                 = true

  site_config {
    {% if cookiecutter.language == "node" -%}
    linux_fx_version = "NODE|10.15"
    {% elif cookiecutter.language == "python" -%}
    linux_fx_version = "PYTHON|3.8"
    {%- endif %}

    cors {
      allowed_origins = ["*"]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [data.external.package_exists]
}

resource "azurerm_function_app" "main" {
  name                       = lower(format("%s-func-%s", var.name_prefix, var.short_name))
  location                   = var.resource_group_location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = var.app_service_plan_id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  app_settings               = merge(var.environment_variables, local.environment_variables, local.secret_variables, local.extra_secrets)
  os_type                    = "linux"
  version                    = "~3"
  https_only                 = true

  site_config {
    {% if cookiecutter.language == "node" -%}
    linux_fx_version = "NODE|10.15"
    {% elif cookiecutter.language == "python" -%}
    linux_fx_version = "PYTHON|3.8"
    {%- endif %}

    cors {
      allowed_origins = ["*"]
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [data.external.package_exists]
}