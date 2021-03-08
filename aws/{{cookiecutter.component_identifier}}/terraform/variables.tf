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

variable "tags" {
  type        = map(string)
  description = "Tags to be used on resources."
}
{% if cookiecutter.use_commercetools|int %}
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
}
{% if cookiecutter.sentry_project %}
variable "sentry_dsn" {
  type    = string
  default = ""
}{% endif %}
{% if cookiecutter.use_public_api|int %}
variable "aws_endpoint_main" {
  type = object({
    url                       = string
    api_gateway_id            = string
    api_gateway_execution_arn = string
  })
}{% endif %}
