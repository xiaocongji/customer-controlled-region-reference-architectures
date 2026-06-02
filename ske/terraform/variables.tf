################################################################################
# Required
################################################################################

variable "organization_id" {
  type        = string
  description = "STACKIT organization ID under which the network area and project are created."
}

variable "cluster_name" {
  type        = string
  description = "Name used for the SKE cluster, project, and as a prefix for network resources. Max 11 characters (STACKIT SKE limit)."

  validation {
    condition     = length(var.cluster_name) <= 11
    error_message = "cluster_name must be 11 characters or fewer (STACKIT SKE limit)."
  }
}

variable "owner_email" {
  type        = string
  description = "Owner email assigned to the STACKIT project."
}

variable "common_labels" {
  type        = map(string)
  default     = {}
  description = "Map of resource labels to apply to all resources that support labelling."
}

################################################################################
# Region / network
################################################################################

variable "region" {
  type        = string
  default     = "eu01"
  description = "STACKIT region to deploy resources into."
}

variable "cluster_cidr" {
  type        = string
  default     = "10.0.0.0/24"
  description = "IPv4 CIDR for the cluster network."
}

variable "additional_sna_ranges" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "Additional IPv4 prefixes added to the STACKIT Network Area, alongside cluster_cidr. Commonly used for a VPN gateway range."
}

variable "transfer_network_cidr" {
  type        = string
  default     = "10.1.0.0/16"
  description = "IPv4 CIDR for the network area's transfer network."
}

variable "network_dns_servers" {
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
  description = "IPv4 nameservers configured on the cluster network."
}

################################################################################
# Cluster
################################################################################

variable "kubernetes_version" {
  type        = string
  description = "The kubernetes version for the cluster. Maps to kubernetes_version_min on stackit_ske_cluster."
}

variable "kubernetes_api_public_access" {
  type        = bool
  default     = false
  description = "When set to true, the Kubernetes API is accessible publicly from the provided authorized networks."
}

variable "kubernetes_api_authorized_networks" {
  type        = list(string)
  default     = []
  description = "The list of CIDRs that can access the Kubernetes API, in addition to the bastion host (which is added by default). When empty, no ACL is applied."
}

################################################################################
# Cluster extensions
################################################################################

variable "dns_enabled" {
  type        = bool
  default     = false
  description = "When set to true, enables the externalDNS extension on the cluster."
}

variable "dns_zones" {
  type        = list(string)
  default     = []
  description = "DNS zones that externalDNS is allowed to manage records in. When empty, all zones are allowed."
}

variable "observability_enabled" {
  type        = bool
  default     = false
  description = "When set to true, enables the STACKIT Observability integration on the cluster."
}

variable "observability_instance_id" {
  type        = string
  default     = null
  description = "ID of the STACKIT Observability instance to send cluster telemetry to. Required when observability_enabled is true."
}

################################################################################
# Node pools
################################################################################

variable "worker_node_pool_min_size" {
  type        = number
  default     = 0
  description = "Minimum number of nodes for messaging and monitoring node pools."
}

variable "node_pool_max_size" {
  type        = number
  default     = 10
  description = "Maximum number of nodes for messaging and monitoring node pools."
}

variable "node_pool_volume_size" {
  type        = number
  default     = 50
  description = "Root volume size in GiB for each node pool. Default is sized for Solace Cloud broker workloads."
}

variable "node_pool_volume_type" {
  type        = string
  default     = "storage_premium_perf2"
  description = "STACKIT block-storage performance class for each node pool's root volume. Default is suitable for Solace Cloud broker workloads."
}

################################################################################
# Bastion
################################################################################

variable "create_bastion" {
  type        = bool
  default     = false
  description = "Whether to create a bastion host. Required to be true when kubernetes_api_access_scope is SNA."
}

variable "bastion_ssh_public_keys" {
  type        = list(string)
  default     = []
  description = "SSH public keys for the operators authorized to log in to the bastion. Each key is installed into the default user's authorized_keys via cloud-init. Must be non-empty when create_bastion is true."
}

variable "bastion_image_id" {
  type        = string
  default     = null
  description = "STACKIT image UUID for the bastion VM. When null (default), the bastion module auto-resolves the latest Ubuntu 24.04 image. Override only when you need a specific or hardened image."
}

variable "bastion_ssh_source_cidrs" {
  type        = list(string)
  default     = []
  description = "Source CIDRs allowed to SSH to the bastion (port 22). One ingress rule is created per CIDR. Must be non-empty when create_bastion is true."
}

variable "bastion_icmp_source_cidrs" {
  type        = list(string)
  default     = []
  description = "Source CIDRs allowed to send ICMP echo (ping) to the bastion. One ingress rule is created per CIDR. Leave empty to omit ICMP entirely."
}

variable "bastion_public_ip_enabled" {
  type        = bool
  default     = true
  description = "Whether to attach a public IP to the bastion. Set false when the bastion is reached via SNA-internal routing only. Note: connect.sh currently tunnels via the public IP, so leave true unless you have an SNA-internal access path."
}

variable "bastion_egress_cidrs" {
  type        = list(string)
  default     = []
  description = "Destination CIDRs the bastion is allowed to reach (egress). One egress rule is created per CIDR. Empty (default) leaves STACKIT's default egress posture untouched."
}

variable "bastion_tags" {
  type        = map(string)
  default     = {}
  description = "Labels merged into the module-default labels and applied to every taggable bastion resource. STACKIT label keys do not allow ':' — use a separator like '_' (e.g. solace_env)."
}
