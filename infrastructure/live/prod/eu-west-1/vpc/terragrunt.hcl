terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws?version=5.19.0"
}

locals {
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  aws_region       = local.region_vars.locals.aws_region
  environment      = local.environment_vars.locals.environment
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  name   = "${local.environment}"
  region = "${local.aws_region}"
  cidr   = "10.0.0.0/16"
  azs    = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]

  private_subnets = ["10.0.0.0/18", "10.0.64.0/18", "10.0.128.0/18"]
  intra_subnets   = ["10.0.192.0/27", "10.0.192.32/27", "10.0.192.64/27"]
  public_subnets  = ["10.0.200.0/27", "10.0.200.32/27", "10.0.200.64/27"]

  enable_nat_gateway = true
  single_nat_gateway = true
}