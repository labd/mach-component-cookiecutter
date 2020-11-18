resource "commercetools_api_client" "main" {
  name  = format("%s_{{ cookiecutter.name|slugify }}", var.name_prefix)
  scope = local.ct_scopes
}
{% if cookiecutter.function_template == "api-extension" %}
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
  key = "{{ cookiecutter.name|replace('_', '-') }}"

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
{% endif %}