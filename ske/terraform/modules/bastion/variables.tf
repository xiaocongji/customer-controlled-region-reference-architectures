variable "cluster_name" {
  type        = string
  description = "Cluster name. Used as a prefix for bastion resource names (e.g. cluster_name + '-bastion', cluster_name + '-bastion-sg')."
}

variable "project_id" {
  type        = string
  description = "STACKIT project ID where the bastion is created."
}

variable "network_id" {
  type        = string
  description = "Project-scoped network ID for the bastion's NIC (the 'network_id' output of the network module). The network area (SNA) is an org-scoped concept handled entirely by the network module — the bastion does not interact with it directly and does not need network_area_id as an input."
}

variable "bastion_ssh_public_keys" {
  type        = list(string)
  description = "SSH public keys for the operators authorized to log in. Each key is written to the default user's authorized_keys via cloud-init."

  validation {
    condition     = length(var.bastion_ssh_public_keys) > 0
    error_message = "At least one SSH public key must be provided — the bastion has no other login method (password auth is disabled)."
  }
}

variable "bastion_image_id" {
  type        = string
  default     = null
  description = "STACKIT image UUID for the bastion VM. When null (default), the module auto-resolves the latest Ubuntu 24.04 image from the STACKIT catalog. Override only when you need a specific or hardened image."
}

variable "machine_type" {
  type        = string
  default     = "g2i.1"
  description = "STACKIT VM flavor for the bastion host. g2i.1 (1 vCPU, 4 GB) is the current equivalent of the deprecated g1.2 — use g2i.2 or larger for ops-heavy Schwarz-style deployments."
}

variable "boot_volume_size" {
  type        = number
  default     = 20
  description = "Boot volume size in GiB for the bastion host."
}

variable "bastion_ssh_source_cidrs" {
  type        = list(string)
  description = "Source CIDRs allowed to SSH to the bastion (port 22). One ingress rule is created per CIDR. Must be non-empty."

  validation {
    condition     = length(var.bastion_ssh_source_cidrs) > 0
    error_message = "At least one SSH source CIDR must be provided — an empty list would create a bastion that nobody can reach."
  }
}

variable "bastion_icmp_source_cidrs" {
  type        = list(string)
  default     = []
  description = "Source CIDRs allowed to send ICMP echo (ping) to the bastion. One ingress rule is created per CIDR. Leave empty to omit ICMP entirely."
}

variable "bastion_egress_cidrs" {
  type        = list(string)
  default     = []
  description = "Destination CIDRs the bastion is allowed to reach (egress). One egress rule is created per CIDR. Defaults to empty, which creates no egress rule and leaves STACKIT's default egress posture untouched (matching prior module behavior). For a hardened SNA posture, set the SNA/VNet ranges plus your StackIT package-mirror ranges."
}

variable "public_ip_enabled" {
  type        = bool
  default     = true
  description = "Whether to attach a public IP to the bastion. Set false when the bastion is reached via SNA-internal routing only."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Labels merged into the module-default labels and applied to every taggable bastion resource. STACKIT label keys do not allow ':' — use a separator like '_' (e.g. solace_env)."
}

variable "common_labels" {
  type        = map(string)
  default     = {}
  description = "Map of resource labels to apply to all resources that support labelling."
}
