terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/ecr/aws//wrappers?version=2.3.1"
}

locals {
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  aws_region       = local.region_vars.locals.aws_region
  environment      = local.environment_vars.locals.environment
  caller_arn       = get_aws_caller_identity_arn()
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  defaults = {
    create = true
    tags = {
      Terraform   = "true"
      Environment = "${local.environment}"
      Region      = "${local.aws_region}"
    }

    repository_read_write_access_arns = ["${local.caller_arn}"]

    repository_lifecycle_policy = jsonencode({
      rules = [
        {
          rulePriority = 1,
          description  = "Keep last 30 images",
          selection = {
            tagStatus     = "tagged",
            tagPrefixList = ["v"],
            countType     = "imageCountMoreThan",
            countNumber   = 30
          },
          action = {
            type = "expire"
          }
        }
      ]
    })
    repository_force_delete         = true
    repository_image_tag_mutability = "MUTABLE"
  }
  items = {
    api = {
      repository_name = "api-${local.environment}"
    }
    migration = {
      repository_name = "migration-${local.environment}"
    }
  }
}
