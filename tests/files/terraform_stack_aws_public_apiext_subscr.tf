
resource "aws_iam_user" "ct_api_extensions" {
  name = "ct-unit-test-user"
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
resource "aws_iam_user" "ct_subscription" {
  name = "ct-unit-test-user"
}

resource "aws_iam_access_key" "ct_subscription" {
  user = aws_iam_user.ct_subscription.name
}

resource "aws_iam_user_policy" "order_created_policy" {
  name = "ct-unit-test-created"
  user = aws_iam_user.ct_subscription.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "SQS:SendMessage"
      ],
      "Effect": "Allow",
      "Resource": "${aws_sqs_queue.ct_order_created_queue.arn}"
    }
  ]
}
EOF
} 

resource "commercetools_subscription" "order_created" {
  key = "unit-test_order_created"

  destination = {
    type          = "SQS"
    queue_url     = aws_sqs_queue.ct_order_created_queue.id
    access_key    = aws_iam_access_key.ct_subscription.id
    access_secret = aws_iam_access_key.ct_subscription.secret
    region        = data.aws_region.current.name
  }

  changes {
    resource_type_ids = ["order"]
  }

  message {
    resource_type_id = "order"
    types            = ["OrderCreated"]
  }

  depends_on = [
    aws_iam_user.ct_subscription_user,
    aws_iam_access_key.ct_subscription,
    aws_sqs_queue.ct_order_created_queue,
    aws_iam_user_policy.order_created_policy,
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

  statement {
    sid       = "AllowSQSPermissions"
    effect    = "Allow"
    resources = [aws_sqs_queue.ct_order_created_queue.arn]
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:SendMessageBatch",
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
  handler       = "index.handler"
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
  allowed_triggers = {
    APIGatewayAny = {
      service = "apigateway"
      arn     = var.api_gateway_execution_arn
    }
  }
}
resource "aws_apigatewayv2_integration" "gateway" {
  api_id           = var.api_gateway
  integration_type = "AWS_PROXY"

  connection_type = "INTERNET"
  description     = "GraphQL Gateway"
  integration_uri = module.lambda_function.this_lambda_function_arn
}

resource "aws_apigatewayv2_route" "application" {
  api_id    = var.api_gateway
  route_key = "ANY /unit-test/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.gateway.id}"
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

resource "aws_sqs_queue" "ct_order_created_queue" {
  name                      = "unit-test-ct-order-created-queue"
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.ct_order_created_deadletter_queue.arn}\",\"maxReceiveCount\":10}"

  # should match lambda timeout
  visibility_timeout_seconds = 600
}

resource "aws_sqs_queue" "ct_order_created_deadletter_queue" {
  name                      = "unit-test-ct-order-created-deadletter-queue"
  receive_wait_time_seconds = 20
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_event_mapping_ct_order_created" {
  batch_size       = 1
  event_source_arn = aws_sqs_queue.ct_order_created_queue.arn
  enabled          = true
  function_name    = module.lambda_function.this_lambda_function_arn

  depends_on = [module.lambda_function]
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


variable "api_gateway" {
  type        = string
  description = "API Gateway to publish in"
}

variable "api_gateway_execution_arn" {
  type        = string
  description = "API Gateway API Execution ARN"
}
