


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
      COMPONENT_NAME              = local.component_name
      ENVIRONMENT                 = var.environment
      SITE                        = var.site
      

      AWS_XRAY_LOG_LEVEL       = "debug"
      AWS_XRAY_DEBUG_MODE      = "true"
      AWS_XRAY_CONTEXT_MISSING = "LOG_ERROR"
    }
  )
}


module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.site}-unit-test"
  description   = "Unit Test component"
  handler       = "src/rest/handler.handler"
  runtime       = "nodejs12.x"
  
  memory_size   = 512
  timeout       = 10

  environment_variables = local.environment_variables

  create_package = false
  s3_existing_package = {
    bucket = local.lambda_s3_repository
    key    = local.lambda_s3_key
  }

  attach_tracing_policy = true
  tracing_mode          = "Active"

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.lambda_policy.json
  publish            = true
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

resource "aws_secretsmanager_secret" "component_secret" {
  for_each = local.secrets
  name     = "${local.component_name}/${replace(each.key, "_", "-")}-secret"

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


