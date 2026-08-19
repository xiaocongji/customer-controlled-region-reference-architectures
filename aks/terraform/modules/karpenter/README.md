# karpenter

Installs [karpenter-provider-azure](https://github.com/Azure/karpenter-provider-azure) as a self-hosted node autoscaler on an AKS cluster: creates the workload-identity-federated managed identity Karpenter runs as, installs the Helm chart with the controller options it requires, and provisions an `AKSNodeClass` plus one `NodePool` per entry in `var.node_pools`.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
