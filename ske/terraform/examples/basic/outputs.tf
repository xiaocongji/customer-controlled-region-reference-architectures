output "bastion_public_ip" {
  value       = module.bastion.bastion_public_ip
  description = "Public IP of the bastion. SSH target: ssh ubuntu@<bastion_public_ip>"
}

output "bastion_private_ip" {
  value       = module.bastion.bastion_private_ip
  description = "Private IP of the bastion on the cluster network."
}

output "ssh_user" {
  value       = module.bastion.ssh_user
  description = "SSH username for the bastion."
}
