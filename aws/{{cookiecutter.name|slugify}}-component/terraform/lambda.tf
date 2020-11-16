module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.site}-{{cookiecutter.name}}"
  description   = "{{ cookiecutter.description }}"
  handler       = "index.handler"
  {% if cookiecutter.language == "node" -%}
  runtime       = "nodejs12.x"
  {% elif cookiecutter.language == "python" -%}
  runtime       = "python3.8"
  {%- endif %}
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
      {% if cookiecutter.sentry_project -%}
      SENTRY_DSN                  = var.sentry_dsn
      {%- endif %}
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
