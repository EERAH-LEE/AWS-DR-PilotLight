# 워크플로우 yaml에 넣을 Role ARN
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
