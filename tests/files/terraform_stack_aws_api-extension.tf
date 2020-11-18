resource "commercetools_api_client" "main" {
  name  = format("%s_unit-test", var.name_prefix)
  scope = local.ct_scopes
}

resource "aws_iam_user" "ct_api_extensions" {
  name = "ct-api-extension-user"
}

resource "aws_iam_access_key" "ct_api_extensions" {
  user = aws_iam_user.ct_api_extensions.name
}

resource "aws_lambda_permission" "ct_api_extension" {
  statement_id  = "AllowCreateOrderLambdaInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.this_lambda_function_arn
  principal     = aws_iam_user.ct_api_extensions.arn
}

resource "commercetools_api_extension" "main" {
  key = "unit-test"

  destination = {
    type          = "AWSLambda"
    arn           = module.lambda_function.this_lambda_function_arn
    access_key    = aws_iam_access_key.ct_api_extensions.id
    access_secret = aws_iam_access_key.ct_api_extensions.secret
  }

  trigger {
    resource_type_id = "cart"
    actions          = ["Create"]
  }

  depends_on = [
    aws_iam_user.ct_api_extensions,
    aws_iam_access_key.ct_api_extensions,
  ]
}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.site}-unit-test"
  description   = "Unit Test component"
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  
  memory_size   = 512
  timeout       = 10

  environment_variables = merge(
    var.environment_variables,
    {
      # Commercetools
      CT_PROJECT_KEY = var.ct_project_key
      CT_SCOPES      = join(",", local.ct_scopes)
      CT_API_URL     = var.ct_api_url
      CT_AUTH_URL    = var.ct_auth_url
      CT_CLIENT_ID   = commercetools_api_client.main.id
      # TODO: We have to see if we can pass this in a seperate
      # 'secrets' attribute so that serverless can store it in a
      # vault/param store
      CT_CLIENT_SECRET            = commercetools_api_client.main.secret
      RELEASE                     = "v@${var.component_version}"
      ENVIRONMENT                 = var.environment
      
    }
  )

  create_package = false
  s3_existing_package = {
    bucket = local.lambda_s3_repository
    key    = local.lambda_s3_key
  }

  attach_tracing_policy = true
  tracing_mode          = "Active"

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.lambda_policy.json

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

}

locals {
  ct_scopes = formatlist("%s:%s", [
    "manage_orders",
    "view_orders",
  ], var.ct_project_key)
  lambda_s3_repository = "mach-lambda-repository"
  lambda_s3_key        = "unit-test-${var.component_version}.zip"
}

terraform {
  required_providers {
    commercetools = {
      source = "labd/commercetools"
    }
  }
}

output "component_version" {
  value = var.component_version
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

variable "variables" {
  type        = map(string)
  description = "Generic way to pass variables to components. Some of these can also be used as environment variables."
}

variable "secrets" {
  type        = map(string)
  description = "Map of secret values. Will be put in the key vault."
}

variable "environment_variables" {
  type        = map(string)
  description = "Explicit map of variables that should be put in this function's environment variables."
}



