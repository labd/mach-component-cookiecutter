resource "azurerm_storage_account" "main" {
  name                     = replace(lower(format("%s-sa-%s", var.azure_name_prefix, var.azure_short_name)), "-", "")
  location                 = var.azure_resource_group.location
  resource_group_name      = var.azure_resource_group.name
  account_tier             = "Standard"
  account_replication_type = local.storage_type
  allow_blob_public_access = false
  
  tags = var.tags
}

{% if cookiecutter.use_commercetools_subscription|int -%}
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
}{% endif %}
