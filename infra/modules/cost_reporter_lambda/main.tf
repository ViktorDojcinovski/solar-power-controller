locals { name = "${var.project}-${var.env}-cost-reporter" }


data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}


resource "aws_iam_role" "lambda" {
  name               = "${local.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}


data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


resource "aws_iam_role_policy" "policy" {
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = [
        "ce:GetCostAndUsage",
        "ce:GetCostForecast",
        "ce:GetDimensionValues"
      ], Resource = "*" },
      { Effect = "Allow", Action = [
        "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"
      ], Resource = "*" }
    ]
  })
}


resource "aws_lambda_function" "fn" {
  function_name    = local.name
  role             = aws_iam_role.lambda.arn
  handler          = "main.handler"
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${local.name}-rule"
  schedule_expression = var.schedule_expression
}


resource "aws_cloudwatch_event_target" "tgt" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.fn.arn
}


resource "aws_lambda_permission" "events" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fn.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}