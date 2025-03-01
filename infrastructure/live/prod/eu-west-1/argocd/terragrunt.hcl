terraform {
  source = "git::git@github.com:vramahandry/terraform-helm-gitops-bridge.git"
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
  create  = false
  install = false
  argocd = {
    chart_version = "7.8.4"
    values        = [file("values.yaml")]
  }
  # apps = {
  #   root-app-infra = file("bootstrap.yaml")
  # }

}

dependency "karpenter" {
    config_path = "../karpenter"

    mock_outputs = {
        karpenter_output = "mock-karpenter-output"
    }
}


dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_endpoint                   = "https://my_cluster.com"
    cluster_name                       = "${local.environment}"
    cluster_certificate_authority_data = "ZmFrZQ==" #fake
  }
}

generate "provider_k8s" {
  path      = "provider_k8s.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF

provider "helm" {
  kubernetes {
    host                   = "${dependency.eks.outputs.cluster_endpoint}"
    cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_certificate_authority_data}")

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}", "--region", "${local.aws_region}" ]
    }
  }
}

provider "kubernetes" {
  host                   = "${dependency.eks.outputs.cluster_endpoint}"
  cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_certificate_authority_data}")

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}", "--region", "${local.aws_region}" ]
  }
}

EOF
}
