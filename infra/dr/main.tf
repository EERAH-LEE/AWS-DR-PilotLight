data "terraform_remote_state" "core" {
  backend = "s3"

  config = {
    bucket = "tfstate-azsis-kbeauty"
    key    = "aws/core/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

module "nat" {
  source = "./nat"

  namespace              = var.namespace
  public_subnet_id       = data.terraform_remote_state.core.outputs.public_subnet_ids[0]
  private_route_table_id = data.terraform_remote_state.core.outputs.private_route_table_id
}