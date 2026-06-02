module "bastion" {
  source = "../../modules/bastion"

  cluster_name = var.cluster_name
  project_id   = var.project_id
  network_id   = var.network_id

  bastion_ssh_public_keys  = var.ssh_public_keys
  bastion_ssh_source_cidrs = var.allowed_ssh_cidrs

  public_ip_enabled = true
}
