resource "azurerm_user_assigned_identity" "karpenter" {
  name                = "karpenter-identity"
  resource_group_name = var.resource_group_name
  location            = var.region

  tags = var.common_tags
}

resource "azurerm_role_assignment" "vnet" {
  scope                = var.virtual_network_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.karpenter.principal_id
}

resource "azurerm_role_assignment" "subnet" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.karpenter.principal_id
}

resource "azurerm_role_assignment" "node_rg_vm_contributor" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.node_resource_group}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.karpenter.principal_id
}

resource "azurerm_role_assignment" "node_rg_network_contributor" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.node_resource_group}"
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.karpenter.principal_id
}

resource "azurerm_role_assignment" "node_rg_managed_identity_operator" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.node_resource_group}"
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.karpenter.principal_id
}

# Subject must match the karpenter controller's ServiceAccount name/namespace exactly for OIDC federation to succeed.
resource "azurerm_federated_identity_credential" "karpenter" {
  name                = "karpenter-federated-cred"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.karpenter.id
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:${var.karpenter_namespace}:karpenter"
  audience            = ["api://AzureADTokenExchange"]
}

# karpenter-provider-azure requires a TLS bootstrapping token (KUBELET_BOOTSTRAP_TOKEN) so
# Karpenter-provisioned VMs can join the cluster. AKS's own bootstrap token secrets are named
# dynamically, so instead of reading one we mint a dedicated one for Karpenter here.
resource "random_string" "bootstrap_token_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "bootstrap_token_secret" {
  length  = 16
  special = false
  upper   = false
}

resource "kubectl_manifest" "karpenter_bootstrap_token" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    type       = "bootstrap.kubernetes.io/token"
    metadata = {
      name      = "bootstrap-token-${random_string.bootstrap_token_id.result}"
      namespace = "kube-system"
    }
    stringData = {
      "token-id"                       = random_string.bootstrap_token_id.result
      "token-secret"                   = random_string.bootstrap_token_secret.result
      "usage-bootstrap-authentication" = "true"
      "usage-bootstrap-signing"        = "true"
      "auth-extra-groups"              = "system:bootstrappers:karpenter"
    }
  })
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://mcr.microsoft.com/aks/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  namespace        = var.karpenter_namespace
  create_namespace = true

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = var.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
    value = azurerm_user_assigned_identity.karpenter.client_id
  }

  set {
    name  = "podLabels.azure\\.workload\\.identity/use"
    value = "true"
    type  = "string"
  }

  # Two replicas for HA; leader election stays enabled (unset default).
  set {
    name  = "replicas"
    value = "2"
  }

  # Mitigates ARM throttling under load with many concurrent provisioning requests.
  set {
    name  = "controller.env[0].name"
    value = "GODEBUG"
  }

  set {
    name  = "controller.env[0].value"
    value = "http2client=0"
  }

  # No dedicated settings.* values path exists for these in the chart — must go via controller.env passthrough.
  set {
    name  = "controller.env[1].name"
    value = "VNET_SUBNET_ID"
  }

  set {
    name  = "controller.env[1].value"
    value = var.subnet_id
  }

  set {
    name  = "controller.env[2].name"
    value = "AZURE_NODE_RESOURCE_GROUP"
  }

  set {
    name  = "controller.env[2].value"
    value = var.node_resource_group
  }

  set {
    name  = "controller.env[3].name"
    value = "SSH_PUBLIC_KEY"
  }

  set {
    name  = "controller.env[3].value"
    value = var.ssh_public_key
  }

  set {
    name  = "controller.env[4].name"
    value = "KUBELET_BOOTSTRAP_TOKEN"
  }

  set {
    name  = "controller.env[4].value"
    value = "${random_string.bootstrap_token_id.result}.${random_string.bootstrap_token_secret.result}"
  }

  set {
    name  = "controller.env[5].name"
    value = "AZURE_SUBSCRIPTION_ID"
  }

  set {
    name  = "controller.env[5].value"
    value = var.subscription_id
  }

  set {
    name  = "controller.env[6].name"
    value = "LOCATION"
  }

  set {
    name  = "controller.env[6].value"
    value = var.region
  }

  depends_on = [azurerm_federated_identity_credential.karpenter, kubectl_manifest.karpenter_bootstrap_token]
}

resource "kubectl_manifest" "aks_node_class_default" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.azure.com/v1beta1"
    kind       = "AKSNodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      imageFamily  = "Ubuntu"
      vnetSubnetID = var.subnet_id
      osDiskSizeGB = 128
      maxPods      = 30
      tags = {
        "datacenter-id" = var.datacenter_id
      }
    }
  })

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "node_pool" {
  for_each = var.node_pools

  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = each.key
    }
    spec = {
      limits = each.value.limits
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = each.value.consolidate_after
      }
      template = {
        metadata = {
          labels = each.value.labels
        }
        spec = {
          taints = each.value.taints
          requirements = [
            {
              key      = "karpenter.azure.com/sku-name"
              operator = "In"
              values   = each.value.sku_names
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = [each.value.arch]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            }
          ]
          nodeClassRef = {
            group = "karpenter.azure.com"
            kind  = "AKSNodeClass"
            name  = "default"
          }
        }
      }
    }
  })

  depends_on = [kubectl_manifest.aks_node_class_default]
}
