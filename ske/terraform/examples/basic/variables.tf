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

variable "region" {
  type        = string
  default     = "eu01"
  description = "STACKIT region."
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "SSH public keys for the operators authorized to log in."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "Source CIDRs allowed to SSH to the bastion (port 22)."
}
