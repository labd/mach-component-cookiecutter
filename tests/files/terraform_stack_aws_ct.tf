



data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.lambda_s3_repository}/*",
    ]
  }

  # Secrets manager
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "secretsmanager:ResourceTag/lambda"
      values   = [local.component_name]
    }
  }

  # Logging
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  
}

locals {
  environment_variables = merge(
    var.variables,
    local.secret_references,
    {
      # Commercetools
      CT_PROJECT_KEY = var.ct_project_key
      CT_API_URL     = var.ct_api_url
      

      RELEASE                     = "${local.component_name}@${var.component_version}"
      VERSION                     = var.component_version
      COMPONENT_NAME              = local.component_name
      ENVIRONMENT                 = var.environment
      SITE                        = var.site
      

      

      AWS_XRAY_LOG_LEVEL       = "debug"
      AWS_XRAY_DEBUG_MODE      = "true"
      AWS_XRAY_CONTEXT_MISSING = "LOG_ERROR"
    }
  )
}







locals {
  ct_scopes = formatlist("%s:%s", [
    "manage_orders",
    "view_orders",
  ], var.ct_project_key)
  component_name       = "unit-test"
  lambda_s3_repository = "mach-lambda-repository"
  lambda_s3_key        = "${local.component_name}-${var.component_version}.zip"
}
terraform {
  required_providers {
    commercetools = {
      source = "labd/commercetools"
    }
  }
}

data "aws_region" "current" {}
output "component_version" {
  value = var.component_version
}

locals {
  secrets = var.secrets
  secret_references = merge({
    for key in keys(local.secrets) : "${key}_SECRET_NAME" => aws_secretsmanager_secret.component_secret[key].name
  }, {
    CT_ACCESS_TOKEN_SECRET_NAME = module.ct_secret.name
  })
}

resource "random_id" "main" {
  byte_length = 5
  keepers = {
    # Generate a new id each time set of secrets change
    secrets = join("", tolist(keys(local.secrets)))
  }
}

resource "aws_secretsmanager_secret" "component_secret" {
  for_each = local.secrets
  name     = "${local.component_name}/${replace(each.key, "_", "-")}-secret-${random_id.main.hex}"

  tags = {
    lambda = local.component_name
  }
}

resource "aws_secretsmanager_secret_version" "component_secret" {
  for_each      = local.secrets
  secret_id     = aws_secretsmanager_secret.component_secret[each.key].id
  secret_string = each.value
}

module "ct_secret" {
  source = "git::https://github.com/labd/mach-component-aws-commercetools-token-refresher.git//terraform/secret"

  name   = local.component_name
  site   = var.site
  scopes = local.ct_scopes
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

variable "tags" {
  type        = map(string)
  description = "Tags to be used on resources."
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
    variables = any
    secrets   = any
  }))
  default = {}
}
variable "variables" {
  type        = any
  description = "Generic way to pass variables to components. Some of these can also be used as environment variables."
}

variable "secrets" {
  type        = any
  description = "Map of secret values. Will be put in the key vault."
}



