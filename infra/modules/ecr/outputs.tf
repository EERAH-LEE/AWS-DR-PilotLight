output "repository_urls" {
  value = { for key, repo in aws_ecr_repository.this : key => repo.repository_url }
}

output "repository_arns" {
  value = { for key, repo in aws_ecr_repository.this : key => repo.arn }
}
