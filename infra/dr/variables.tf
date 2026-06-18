variable "namespace" {
  type    = string
  default = "azsis-kbeauty-dr"
}

variable "ecr_repository_names" {
  type    = list(string)
  default = ["web-blue", "web-green", "was-blue", "was-green"]
}

variable "ecr_image_scan_on_push" {
  type    = bool
  default = true
}

variable "eks_kubernetes_version" {
  type    = string
  default = "1.32"
}

variable "eks_service_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "eks_endpoint_public_access" {
  type    = bool
  default = true
}

variable "eks_endpoint_private_access" {
  type    = bool
  default = true
}

variable "eks_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "eks_bootstrap_cluster_creator_admin_permissions" {
  type    = bool
  default = true
}

variable "eks_admin_principal_arns" {
  # EKS 클러스터 생성자 외에 kubectl/Argo CD 등록 권한을 줄 IAM user/role ARN 목록입니다.
  # 현재 예시는 sue AWS profile의 IAM user ARN입니다.
  # 다른 계정/role을 쓰려면 `aws sts get-caller-identity --profile <profile>`의 Arn 값을 넣습니다.
  type    = list(string)
  default = ["arn:aws:iam::946775837287:user/sue"]
}

variable "eks_node_groups" {
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
  }))

  default = {
    mgmtnp = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      labels = {
        workload = "system"
        purpose  = "core"
      }
    }
    appnp = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 8
      desired_size   = 2
      labels = {
        workload = "app"
        purpose  = "web-was"
      }
    }
    monnp = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1
      labels = {
        workload = "monitoring"
        purpose  = "observability"
      }
    }
  }
}
