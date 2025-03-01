terraform {
  source = "${path_relative_from_include()}/../modules//karpenter"
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
  cluster_name                 = dependency.eks.outputs.cluster_name
  irsa_oidc_provider_arn       = dependency.eks.outputs.oidc_provider_arn
}


dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_endpoint                   = "https://my_cluster.com"
    cluster_name                       = "${local.environment}"
    cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURLVENDQWhHZ0F3SUJBZ0lJSXZKNndUdHlIRzB3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBeU1qVXdPVE0zTURkYUZ3MHlOakF5TWpVd09UUXlNRGRhTUR3eApIekFkQmdOVkJBb1RGbXQxWW1WaFpHMDZZMngxYzNSbGNpMWhaRzFwYm5NeEdUQVhCZ05WQkFNVEVHdDFZbVZ5CmJtVjBaWE10WVdSdGFXNHdnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCQVFEMjZoK08KWE1ia2ROQkxnMXV0UERkZFpYN2dNNW5HZklDaTdpc3ZKcGdFZG5VKzk2K1E5eFlTNktjeCtnWTIzamF5bmZzYgpXMGlRVHYzYXFSTDFqS0w4SkFjSHFmZUMrWmhaeDJhcDBxSVlFaUNZMVM0WWltbENZelhRQkcvY3hVVFRnQktjCjBGUExQZzNBM3JncFJqa0VTbStVTnYrM2YxZTJ6MzlvVzRzMFR6dmQzVEpqK1BWeTNGOTczc0Y4TkZUWURVSHgKVjBsalMyWDBydWp5a0ZobzRVcW9OcDI5OG96UzJKeFloWGhZSmoyZGFCZUdGSFE3RlN5dzZCZkN4T0tjL2U2TQo2ZkFCNDlVUEV4QnZJeC9UMUdmRXdTMGFqdkMwazl3bDJiTEJWREJtb1lWSmJKT1JSZjY2eWpxMmd0V3A3RnJFCkFlTnphalUzT0dKOXE0dDdBZ01CQUFHalZqQlVNQTRHQTFVZER3RUIvd1FFQXdJRm9EQVRCZ05WSFNVRUREQUsKQmdnckJnRUZCUWNEQWpBTUJnTlZIUk1CQWY4RUFqQUFNQjhHQTFVZEl3UVlNQmFBRkZaZUNQY3BYd2R2NU5aLwpxUmxCbVhadDRKNXNNQTBHQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUJSd3NDUFp6U2dSQTNBMWNuLzh3Ni9xRFE0CnhHRWtBVlBCdVJhWWh1Qkc1cFlzQm0xZ0UyVFNZbExUdlpYR0I2Y0JEMFIrRVhVbFBPMGRzaXREbFN5a2ZwMTMKdXZrbTZHdURpa0lpcnlFV2dEaW9vQjB6VTM2RzlKelJ6TEs0dTBnYklYUnRTQjJoN2hCOThUU0xRVkNDeDdhdgpuN1RzazNaL3J0cThPS01KakhIdDQvSER4Sys1UTdvYkgwV0VKdWlVYTEvUm1QR2RtZWpmMkovbWx0ZklGM0NiClNoMGtCWkUzT2Z2TjJ1TElDNU5BMytKelIxNjFUWkNYelY3YzdFaFdBY0pPdGJobDN4N1RUdzZaWUtZYitTZDQKTVRjRnVkdHR0cU9YdXZza0pwSDVTL0VDZFdFRWtjOWxZcFhZeFMwekM5d3Q2ZU1VKy84YlMxU0YybWkxCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K" #fake
    oidc_provider_arn                  = "arn:aws:iam::376129852544:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/fake"
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

provider "kubectl" {
  host                   = "${dependency.eks.outputs.cluster_endpoint}"
  cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_certificate_authority_data}")
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}", "--region", "${local.aws_region}" ]
  }
}

EOF
}
