output "bastion_private_ip" {
  value       = module.bastion.bastion_private_ip
  description = "Private IP of the bastion on the cluster network. Used for SNA-internal access."
}

output "bastion_security_group_id" {
  value       = module.bastion.bastion_security_group_id
  description = "Security group ID of the bastion."
}

output "ssh_user" {
  value       = module.bastion.ssh_user
  description = "SSH username for the bastion."
}
