terraform {
  source = "${path_relative_from_include()}/../modules//rds"
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

  db_name            = "${local.environment}"
  db_instance_class  = "db.t4g.small"
  db_master_username = "postgres"
  db_master_password = "postgres"
  db_subnet_group    = dependency.vpc.outputs.database_subnet_group
  db_multi_az        = true

  vpc_id         = dependency.vpc.outputs.vpc_id
  vpc_cidr_block = dependency.vpc.outputs.vpc_cidr_block


}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                = "fake-vpc-id"
    private_subnets       = ["subnet-1234", "subnet-2345", "subnet-3456"]
    database_subnet_group = "fake"
    vpc_cidr_block        = "10.0.0.0/16"
  }
}