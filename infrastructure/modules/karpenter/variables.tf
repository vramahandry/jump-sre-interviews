variable "cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = ""
}

variable "enable_irsa" {
  description = "Determines whether to enable support for IAM role for service accounts"
  type        = bool
  default     = false
}

variable "irsa_oidc_provider_arn" {
  description = "OIDC provider arn used in trust policy for IAM role for service accounts"
  type        = string
  default     = ""
}

variable "irsa_namespace_service_accounts" {
  description = "List of `namespace:serviceaccount`pairs to use in trust policy for IAM role for service accounts"
  type        = list(string)
  default     = ["kube-system:karpenter"]
}

variable "access_entry_type" {
  description = "Type of the access entry. `EC2_LINUX`, `FARGATE_LINUX`, or `EC2_WINDOWS`; defaults to `EC2_LINUX`"
  type        = string
  default     = "EC2_LINUX"
}

variable "karpenter_values" {
  description = "Values to passed to karpenter helm chart"
  type        = list(string)
  default     = []
}