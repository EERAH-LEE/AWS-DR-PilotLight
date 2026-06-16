locals {
    org     = "azsis"
    project = "kbeauty-dr"
    aws_region = "ap-northeast-2"

    namespace = "${local.org}-${local.project}"
}