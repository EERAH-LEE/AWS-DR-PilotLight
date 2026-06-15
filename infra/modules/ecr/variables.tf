variable "namespace" {
  type = string
}

variable "repository_names" {
  type = list(string)
}

variable "image_scan_on_push" {
  type = bool
}
