locals {
  storage_type     = var.environment == "production" ? "ZRS" : "LRS"
  ct_scopes = formatlist("%s:%s", [
    "manage_products",
    "manage_orders",
  ], var.ct_project_key)
}
