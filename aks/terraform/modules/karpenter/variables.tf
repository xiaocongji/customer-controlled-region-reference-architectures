variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID the cluster is deployed in."
}

variable "region" {
  type        = string
  description = "The Azure region of the cluster."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group containing the AKS cluster."
}

variable "node_resource_group" {
  type        = string
  description = "The AKS-managed node resource group (MC_ prefix)."
}

variable "cluster_name" {
  type        = string
  description = "The AKS cluster name."
}

variable "datacenter_id" {
  type        = string
  description = "An identifier used to tag Karpenter-provisioned nodes, e.g. for cost attribution."
}

variable "virtual_network_id" {
  type        = string
  description = "The resource ID of the cluster's VNet."
}

variable "subnet_id" {
  type        = string
  description = "The resource ID of the cluster's node subnet."
}

variable "oidc_issuer_url" {
  type        = string
  description = "The AKS cluster's OIDC issuer URL, used to federate the Karpenter managed identity with its ServiceAccount."
}

variable "cluster_endpoint" {
  type        = string
  description = "The AKS cluster's Kubernetes API server endpoint, e.g. https://<fqdn>:443. Required by the karpenter-provider-azure controller to bootstrap new nodes."
}

variable "ssh_public_key" {
  type        = string
  description = "The SSH public key installed on Karpenter-provisioned VMs."
}

variable "karpenter_namespace" {
  type        = string
  default     = "karpenter"
  description = "The namespace to install the Karpenter Helm release into."
}

variable "karpenter_version" {
  type        = string
  default     = "1.14.0"
  description = "Version of the karpenter-provider-azure Helm chart to install."
}

variable "node_pools" {
  description = "Karpenter NodePools to provision, keyed by pool name."
  type = map(object({
    labels = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    sku_names         = list(string) # exact VM sizes this pool may use (karpenter.azure.com/sku-name)
    arch              = string       # "amd64" or "arm64"
    consolidate_after = string       # e.g. "1m", "10m"
    limits = optional(object({
      cpu    = string
      memory = string
    }), { cpu = "1000", memory = "1000Gi" })
  }))
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Tags that are added to all resources created by this module."
}
