terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/eks/aws?version=20.33.1"
}

locals {
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  aws_region       = local.region_vars.locals.aws_region
  environment      = local.environment_vars.locals.environment
  my_public_ip     = run_cmd("curl", "-s", "-4", "ifconfig.me")
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {

  cluster_name    = "${local.environment}"
  cluster_version = "1.31"

  # EKS Addons
  cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
    }
    kube-proxy = {}
    vpc-cni    = {}
  }

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  create_cluster_sg               = true
  cluster_security_group_additional_rules = {
    ingress_public = {
      description = "Public to cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["${local.my_public_ip}/32"]
    }

  }

  cluster_encryption_config = {}

  create_cloudwatch_log_group = false

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets

  eks_managed_node_groups = {
    test = {
      ami_type       = "BOTTLEROCKET_ARM_64"
      instance_types = ["t4g.small"]

      min_size = 1
      max_size = 1
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 1

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
      taints = {
        # The pods that do not tolerate this taint should run on nodes
        # created by Karpenter
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }
  node_security_group_tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = "${local.environment}"
  }

  enable_cluster_creator_admin_permissions = true

}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id          = "fake-vpc-id"
    private_subnets = ["subnet-1234", "subnet-2345", "subnet-3456"]
  }
}