variable "project_id" {
  type        = string
  description = "STACKIT project ID to deploy the bastion into."
}

variable "network_id" {
  type        = string
  description = "Network ID for the bastion's NIC (from the network module)."
}

variable "cluster_name" {
  type        = string
  description = "Name prefix for bastion resources. Max 11 characters."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for the operator authorized to log in to the bastion."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "Source CIDRs allowed to SSH to the bastion. Scope to Solace office and VPN ranges."
}
