locals {
  storage_type     = var.environment == "production" ? "ZRS" : "LRS"
}
