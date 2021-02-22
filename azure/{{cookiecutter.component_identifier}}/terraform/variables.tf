variable "short_name" {
  type        = string
  description = "Short name passed by MACH. Will not be more than 10 characters"
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

variable "app_service_plan" {
  type = object({
    id   = string
    name = string
  })
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

{% if cookiecutter.use_commercetools|int -%}
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
    variables = map(string)
    secrets   = map(string)
  }))
  default = {}
}{% endif %}

variable "variables" {
  type        = map(string)
  description = "Generic way to pass variables to components. Some of these can also be used as environment variables."
}

variable "secrets" {
  type        = map(string)
  description = "Map of secret values. Will be put in the key vault."
  default     = {}
}
