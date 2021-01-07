resource "aws_sqs_queue" "ct_order_created_queue" {
  name                      = "{{ cookiecutter.name|slugify }}-ct-order-created-queue"
  receive_wait_time_seconds = 20
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.ct_order_created_deadletter_queue.arn}\",\"maxReceiveCount\":10}"

  # should match lambda timeout
  visibility_timeout_seconds = 600
}

resource "aws_sqs_queue" "ct_order_created_deadletter_queue" {
  name                      = "{{ cookiecutter.name|slugify }}-ct-order-created-deadletter-queue"
  receive_wait_time_seconds = 20
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_event_mapping_ct_order_created" {
  batch_size       = 1
  event_source_arn = aws_sqs_queue.ct_order_created_queue.arn
  enabled          = true
  function_name    = module.subscription_function.this_lambda_function_arn

  depends_on = [module.subscription_function]
}
