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

variable "ssh_public_keys" {
  type        = list(string)
  description = "SSH public keys for the operators authorized to log in."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "Source CIDRs allowed to SSH to the bastion (port 22)."
}

variable "bastion_image_id" {
  type        = string
  default     = "b74faf8a-41d4-4e02-b0b0-b6205ac44e8a"
  description = "STACKIT image UUID for the bastion VM. Default is Ubuntu 24.04 LTS (eu01)."
}
