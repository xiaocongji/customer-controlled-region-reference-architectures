module "bastion" {
  source = "../../modules/bastion"

  cluster_name = var.cluster_name
  project_id   = var.project_id
  network_id   = var.network_id

  bastion_ssh_public_key   = var.ssh_public_key
  bastion_ssh_source_cidrs = var.allowed_ssh_cidrs
  machine_type             = "g2i.2"

  tags = {
    solace_env      = "prod"
    solace_customer = "schwarz"
    solace_region   = "eu01"
  }
}
