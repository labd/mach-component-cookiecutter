resource "azurerm_storage_account" "main" {
  name                     = replace(lower(format("%s-sa-%s", var.name_prefix, var.short_name)), "-", "")
  location                 = var.resource_group_location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = local.storage_type
  allow_blob_public_access = false
  
  tags = var.tags
}
