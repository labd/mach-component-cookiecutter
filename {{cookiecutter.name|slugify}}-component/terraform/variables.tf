# azure stuff
variable "short_name" {
  type        = string
  description = "Short name passed by Mull. Will not be more than 10 characters"
}

variable "name_prefix" {
  type = string
}

variable "context" {
  type = object({
    company     = string
    agency      = string
    provisioner = string
    environment = string
    solution    = string
    entity      = string
    region      = string
    tags        = map(string)
  })
  default = {
    company     = ""
    agency      = ""
    provisioner = ""
    environment = ""
    solution    = ""
    entity      = ""
    region      = ""
    tags        = {}
  }
  description = "Default context to use for passing state between label modules"
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

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`"
}

# function app specific
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

variable "stores" {
  type        = list(string)
  default     = []
  description = "List of Commercetools store keys used in this Commercetools environment."
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

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Explicit map of variables that should be put in this function's environment variables."
}

variable "ct_project_key" {
  type = string
  default = ""
}