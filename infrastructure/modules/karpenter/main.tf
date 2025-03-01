module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~>20.33"

  enable_v1_permissions           = true
  enable_irsa                     = true
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = "KarpenterNodeRole-${var.cluster_name}"
  irsa_oidc_provider_arn          = var.irsa_oidc_provider_arn
  irsa_namespace_service_accounts = var.irsa_namespace_service_accounts
  cluster_name                    = var.cluster_name

  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

}

resource "helm_release" "karpenter" {
  namespace  = "kube-system"
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.2.0"
  wait       = true

  values = concat([
    <<-EOT
    replicas: '1'
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    podAntiAffinity: {}
    nodeSelector:
      karpenter.sh/controller: 'true'
    dnsPolicy: Default
    settings:
      clusterName: ${var.cluster_name}
      interruptionQueue: ${module.karpenter.queue_name}
    webhook:
      enabled: false
    tolerations:
      - key: karpenter.sh/controller
        operator: Exists
        effect: NoSchedule
    EOT
  ], var.karpenter_values)
}

resource "kubectl_manifest" "karpenter_nodepools" {
  for_each = fileset("config/nodepools", "*.yaml")
  yaml_body = templatefile("config/nodepools/${each.value}", {
    cluster_name   = var.cluster_name
    node_role_name = module.karpenter.node_iam_role_name
  })
  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_ec2nodeclasses" {
  for_each = fileset("config/ec2nodeclasses", "*.yaml")
  yaml_body = templatefile("config/ec2nodeclasses/${each.value}", {
    cluster_name   = var.cluster_name
    node_role_name = module.karpenter.node_iam_role_name
  })
  depends_on = [helm_release.karpenter]
}