locals {
  user_data = "#cloud-config\n${yamlencode({
    ssh_pwauth          = false
    disable_root        = true
    ssh_authorized_keys = var.ssh_public_keys
  })}"
}

module "bastion" {
  source = "../../modules/bastion"

  cluster_name = var.cluster_name
  project_id   = var.project_id
  network_id   = var.network_id

  user_data                = local.user_data
  bastion_image_id         = var.bastion_image_id
  bastion_ssh_source_cidrs = var.allowed_ssh_cidrs
}
