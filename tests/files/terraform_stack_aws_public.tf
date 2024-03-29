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
      

      RELEASE                     = "${local.component_name}@${var.component_version}"
      VERSION                     = var.component_version
      COMPONENT_NAME              = local.component_name
      ENVIRONMENT                 = var.environment
      SITE                        = var.site
      

      

      NODE_ENV                 = "production"
      AWS_XRAY_LOG_LEVEL       = "debug"
      AWS_XRAY_DEBUG_MODE      = "true"
      AWS_XRAY_CONTEXT_MISSING = "LOG_ERROR"
    }
  )
}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"
  version = "2.24.0"

  function_name = "${var.site}-unit-test"
  description   = "Unit Test component"
  handler       = "src/http/index.handler"
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
  
  allowed_triggers = {
    APIGatewayAny = {
      service = "apigateway"
      arn     = var.aws_endpoint_main.api_gateway_execution_arn
    }
  }
}

resource "aws_apigatewayv2_integration" "gateway" {
  api_id           = var.aws_endpoint_main.api_gateway_id
  integration_type = "AWS_PROXY"

  connection_type = "INTERNET"
  description     = "unit-test HTTP Gateway"
  integration_uri = module.lambda_function.lambda_function_arn
}

resource "aws_apigatewayv2_route" "application" {
  api_id    = var.aws_endpoint_main.api_gateway_id
  route_key = "ANY /unit-test/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.gateway.id}"
}





locals {
  
  component_name       = "unit-test"
  lambda_s3_repository = "mach-lambda-repository"
  lambda_s3_key        = "${local.component_name}-${var.component_version}.zip"
}


data "aws_region" "current" {}
output "component_version" {
  value = var.component_version
}

locals {
  secrets = merge(var.secrets, {
    
  })
  secret_references = {
    for key in keys(local.secrets) : "${key}_SECRET_NAME" => aws_secretsmanager_secret.component_secret[key].name
  }
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

variable "variables" {
  type        = any
  description = "Generic way to pass variables to components. Some of these can also be used as environment variables."
}

variable "secrets" {
  type        = any
  description = "Map of secret values. Will be put in the key vault."
}


variable "aws_endpoint_main" {
  type = object({
    url                       = string
    api_gateway_id            = string
    api_gateway_execution_arn = string
  })
}

