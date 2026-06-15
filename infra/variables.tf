variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}


# Azure DB 정보
variable "azure_mysql_host" {
  type = string
}

variable "azure_mysql_username" {
  type = string
}

variable "azure_mysql_password" {
  type      = string
  sensitive = true
}

#Azure Traffic Manager DNS
variable "azure_endpoint" {
  type = string
}

variable "ecr_repository_names" {
  description = "ECR repositories for blue/green web and WAS images."
  type        = list(string)
  default     = ["web-blue", "web-green", "was-blue", "was-green"]
}

variable "ecr_image_scan_on_push" {
  description = "Run ECR image scans when images are pushed."
  type        = bool
  default     = true
}

variable "eks_kubernetes_version" {
  description = "EKS Kubernetes version for the AWS DR cluster."
  type        = string
  default     = "1.32"
}

variable "eks_service_cidr" {
  description = "Kubernetes service CIDR for EKS. Keep this separate from the VPC and Azure AKS CIDRs."
  type        = string
  default     = "10.30.0.0/16"
}

variable "eks_endpoint_public_access" {
  description = "Enable public access to the EKS API endpoint."
  type        = bool
  default     = true
}

variable "eks_endpoint_private_access" {
  description = "Enable private access to the EKS API endpoint from the VPC."
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the EKS public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_node_groups" {
  description = "EKS managed node groups mapped from the Azure AKS node pools."
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
