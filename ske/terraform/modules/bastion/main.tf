data "stackit_image_v2" "ubuntu_lts" {
  count      = var.bastion_image_id == null ? 1 : 0
  project_id = var.project_id
  name_regex = "^Ubuntu 22\\.04$"
  filter = {
    distro = "ubuntu"
  }
}

locals {
  resolved_image_id = var.bastion_image_id != null ? var.bastion_image_id : data.stackit_image_v2.ubuntu_lts[0].image_id

  # STACKIT label keys cannot contain ':'. Module-default labels use '_'; caller tags
  # are merged on top and win on key collisions. common_labels wins last.
  default_labels = {
    solace_module = "bastion"
  }
  labels = merge(local.default_labels, var.tags, var.common_labels)
}

resource "stackit_security_group" "bastion_sg" {
  project_id = var.project_id
  name       = "${var.cluster_name}-bastion-sg"
  stateful   = true
  labels     = local.labels
}

resource "stackit_security_group_rule" "ssh" {
  for_each = toset(var.bastion_ssh_source_cidrs)

  project_id        = var.project_id
  security_group_id = stackit_security_group.bastion_sg.security_group_id
  direction         = "ingress"
  ether_type        = "IPv4"
  port_range = {
    max = 22
    min = 22
  }
  protocol = {
    name = "tcp"
  }
  ip_range = each.value
}

resource "stackit_security_group_rule" "icmp" {
  for_each = toset(var.bastion_icmp_source_cidrs)

  project_id        = var.project_id
  security_group_id = stackit_security_group.bastion_sg.security_group_id
  direction         = "ingress"
  icmp_parameters = {
    code = 0
    type = 8
  }
  protocol = {
    name = "icmp"
  }
  ip_range = each.value
}

resource "stackit_security_group_rule" "egress" {
  for_each = toset(var.bastion_egress_cidrs)

  project_id        = var.project_id
  security_group_id = stackit_security_group.bastion_sg.security_group_id
  direction         = "egress"
  ether_type        = "IPv4"
  ip_range          = each.value
}

resource "stackit_network_interface" "bastion_nic" {
  project_id         = var.project_id
  network_id         = var.network_id
  security_group_ids = [stackit_security_group.bastion_sg.security_group_id]
  labels             = local.labels
}

resource "stackit_key_pair" "bastion" {
  count = var.bastion_ssh_public_key != null ? 1 : 0

  name       = "${var.cluster_name}-bastion"
  public_key = var.bastion_ssh_public_key
}

resource "stackit_server" "bastion" {
  project_id = var.project_id
  name       = "${var.cluster_name}-bastion"
  boot_volume = {
    size                  = var.boot_volume_size
    source_type           = "image"
    source_id             = local.resolved_image_id
    delete_on_termination = true
  }

  machine_type = var.machine_type
  keypair_name = one(stackit_key_pair.bastion[*].name)
  user_data    = var.user_data
  labels       = local.labels
  network_interfaces = [
    stackit_network_interface.bastion_nic.network_interface_id
  ]
}

resource "stackit_public_ip" "bastion_public_ip" {
  project_id           = var.project_id
  network_interface_id = stackit_network_interface.bastion_nic.network_interface_id
  labels               = local.labels
}
