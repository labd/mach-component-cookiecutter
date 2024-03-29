
resource "aws_iam_user" "ct_api_extensions" {
  name = "ct-unit-test-user"
}

resource "aws_iam_access_key" "ct_api_extensions" {
  user = aws_iam_user.ct_api_extensions.name
}

resource "aws_lambda_permission" "ct_api_extension" {
  statement_id  = "AllowCreateOrderLambdaInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.extension_function.lambda_function_arn
  principal     = aws_iam_user.ct_api_extensions.arn
}

resource "commercetools_api_extension" "main" {
  key = "unit-test"

  destination = {
    type          = "AWSLambda"
    arn           = module.extension_function.lambda_function_arn
    access_key    = aws_iam_access_key.ct_api_extensions.id
    access_secret = aws_iam_access_key.ct_api_extensions.secret
  }

  trigger {
    resource_type_id = "order"
    actions          = ["Create"]
  }

  depends_on = [
    aws_iam_user.ct_api_extensions,
    aws_iam_access_key.ct_api_extensions,
  ]
}


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
      

      ORDER_PREFIX                = lookup(var.variables, "ORDER_PREFIX", "")
      INITIAL_ORDER_NUMBER        = lookup(var.variables, "INITIAL_ORDER_NUMBER", 0)

      NODE_ENV                 = "production"
      AWS_XRAY_LOG_LEVEL       = "debug"
      AWS_XRAY_DEBUG_MODE      = "true"
      AWS_XRAY_CONTEXT_MISSING = "LOG_ERROR"
    }
  )
}



module "extension_function" {
  source = "terraform-aws-modules/lambda/aws"
  version = "2.24.0"

  function_name = "${var.site}-unit-test-extension"
  description   = "Unit Test component commercetools api extension"
  handler       = "src/extensions/index.handler"
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



