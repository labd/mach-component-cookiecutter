resource "commercetools_api_client" "main" {
  name  = format("%s_unit-test", var.name_prefix)
  scope = local.ct_scopes
}

# Start commercetools API extension
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

data "aws_region" "current" {}
output "component_version" {
  value = var.component_version
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



