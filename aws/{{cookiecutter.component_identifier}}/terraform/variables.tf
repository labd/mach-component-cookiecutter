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
}

variable "variables" {
  type        = map(string)
  description = "Generic way to pass variables to components. Some of these can also be used as environment variables."
}

variable "secrets" {
  type        = map(string)
  description = "Map of secret values. Will be put in the key vault."
}

{% if cookiecutter.sentry_project -%}
variable "sentry_dsn" {
  type    = string
  default = ""
}
{%- endif %}
{% if cookiecutter.use_public_api|int -%}
variable "api_gateway" {
  type        = string
  description = "API Gateway to publish in"
}

variable "api_gateway_execution_arn" {
  type        = string
  description = "API Gateway API Execution ARN"
}
{%- endif %}