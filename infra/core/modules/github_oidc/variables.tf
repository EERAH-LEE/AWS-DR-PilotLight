variable "namespace" {
  type = string
}

# GitHub 레포 (org/repo 형식)
# 이 레포에서 실행되는 Actions만 Role 사용 가능
variable "github_repo" {
  type        = string
  description = "ex) bespin-multi-cloud-3-azure/final_pj_aws"
}
