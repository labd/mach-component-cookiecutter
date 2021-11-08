locals {
  environment_variables = merge(
    var.variables,
    local.secret_references,
    {
      {% if cookiecutter.use_commercetools|int -%}
      # Commercetools
      CT_PROJECT_KEY = var.ct_project_key
      CT_API_URL     = var.ct_api_url
      {% if not cookiecutter.use_commercetools_token_rotator|int -%}
      CT_CLIENT_ID   = commercetools_api_client.main.id
      CT_SCOPES      = join(",", local.ct_scopes)
      CT_AUTH_URL    = var.ct_auth_url{% endif %}{% endif %}

      RELEASE                     = "${local.component_name}@${var.component_version}"
      VERSION                     = var.component_version
      COMPONENT_NAME              = local.component_name
      ENVIRONMENT                 = var.environment
      SITE                        = var.site
      {% if cookiecutter.sentry_project -%}
      SENTRY_DSN                  = var.sentry_dsn{% endif %}

      {% if cookiecutter.use_commercetools_api_extension|int -%}
      ORDER_PREFIX                = lookup(var.variables, "ORDER_PREFIX", "")
      INITIAL_ORDER_NUMBER        = lookup(var.variables, "INITIAL_ORDER_NUMBER", 0){% endif %}

      NODE_ENV                 = "production"
      AWS_XRAY_LOG_LEVEL       = "debug"
      AWS_XRAY_DEBUG_MODE      = "true"
      AWS_XRAY_CONTEXT_MISSING = "LOG_ERROR"
    }
  )
}

{% if cookiecutter.use_public_api|int -%}
module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"
  version = "2.24.0"

  function_name = "${var.site}-{{cookiecutter.name}}"
  description   = "{{ cookiecutter.description }}"
  handler       = "src/http/index.handler"
  {% if cookiecutter.language == "node" -%}
  runtime       = "nodejs12.x"{% elif cookiecutter.language == "python" -%}
  runtime       = "python3.8"{% endif %}
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
  
  {% if cookiecutter.use_public_api|int -%}
  allowed_triggers = {
    APIGatewayAny = {
      service = "apigateway"
      arn     = var.aws_endpoint_main.api_gateway_execution_arn
    }
  }{% endif %}
}

{% if cookiecutter.use_public_api|int -%}
resource "aws_apigatewayv2_integration" "gateway" {
  api_id           = var.aws_endpoint_main.api_gateway_id
  integration_type = "AWS_PROXY"

  connection_type = "INTERNET"
  description     = "{{ cookiecutter.name }} HTTP Gateway"
  integration_uri = module.lambda_function.lambda_function_arn
}

resource "aws_apigatewayv2_route" "application" {
  api_id    = var.aws_endpoint_main.api_gateway_id
  route_key = "ANY /{{ cookiecutter.name|slugify }}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.gateway.id}"
}{% endif %}{% endif %}

{% if cookiecutter.use_commercetools_api_extension|int -%}
module "extension_function" {
  source = "terraform-aws-modules/lambda/aws"
  version = "2.24.0"

  function_name = "${var.site}-{{cookiecutter.name}}-extension"
  description   = "{{ cookiecutter.description }} commercetools api extension"
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
{% endif %}

{% if cookiecutter.use_commercetools_subscription|int -%}
module "subscription_function" {
  source  = "terraform-aws-modules/lambda/aws"

  function_name = "${var.site}-{{cookiecutter.name}}-subscription"
  description   = "{{ cookiecutter.description }} commercetools subscriptions"
  handler       = "src/subscriptions/index.handler"
  runtime       = "nodejs12.x"

  memory_size = 512
  timeout     = 10

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
}{% endif %}
