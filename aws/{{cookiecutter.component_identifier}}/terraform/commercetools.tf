{% if not cookiecutter.use_commercetools_token_rotator|int -%}
resource "commercetools_api_client" "main" {
  name  = "{{ cookiecutter.name|slugify }}"
  scope = local.ct_scopes
}
{% endif %}
{% if cookiecutter.use_commercetools_api_extension|int -%}
resource "aws_iam_user" "ct_api_extensions" {
  name = "ct-{{ cookiecutter.name|slugify }}-user"
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
  key = "{{ cookiecutter.name|slugify }}"

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
{%- endif %}
{% if cookiecutter.use_commercetools_subscription|int -%}
resource "aws_iam_user" "ct_subscription" {
  name = "ct-{{ cookiecutter.name|slugify }}-user"
}

resource "aws_iam_access_key" "ct_subscription" {
  user = aws_iam_user.ct_subscription.name
}

resource "aws_iam_user_policy" "order_created_policy" {
  name = "ct-{{ cookiecutter.name|slugify }}-created"
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
  key = "{{ cookiecutter.name|slugify }}_order_created"

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
{%- endif %}