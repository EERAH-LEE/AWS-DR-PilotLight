output "sns_topic_arn" {
  value = aws_sns_topic.dr_alert.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.health_checker.function_name
}
