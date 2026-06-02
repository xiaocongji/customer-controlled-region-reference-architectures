# bastion

A hardened SSH jump host into a STACKIT region. It provisions a single VM on one of the
project's networks, optionally attaches a public IP, and locks SSH ingress to an operator
allow-list. It is the controlled entry point for emergency node access and `kubectl` from
inside the network area once the SKE control plane is private (`access_scope = "SNA"`).

SSH key material is an **input** — the module never generates or stores secrets.

## How an operator uses it

The bastion is a jump host; you do not run workloads on it. To reach a private cluster node:

```sh
ssh -J ubuntu@<bastion_public_ip> ubuntu@<node-internal-ip>
```

`connect.sh` at the repo root automates the equivalent for `kubectl`: when the cluster API is
private it opens a SOCKS tunnel through the bastion (`ssh ubuntu@<bastion_public_ip> -D ...`)
and points the kubeconfig proxy at it. The `bastion_public_ip` and `bastion_username` outputs
are the values that go into the team's operator runbook.

## Hardening choices

- **Key-only auth.** cloud-init installs every key in `bastion_ssh_public_keys` into the
  default `ubuntu` user's `authorized_keys`, sets `ssh_pwauth: false` (no password auth), and
  `disable_root: true`. Multiple keys are supported here because `stackit_server.keypair_name`
  only accepts one keypair — cloud-init is the only multi-operator path.
- **Tight ingress.** The security group permits inbound TCP/22 only from
  `bastion_ssh_source_cidrs` (one rule per CIDR). ICMP is opt-in via `bastion_icmp_source_cidrs`.
- **Tunable egress.** `bastion_egress_cidrs` is empty by default, which leaves STACKIT's default
  egress posture untouched. Set it to the SNA/VNet ranges (plus package mirrors) to lock egress
  down. Because the module installs nothing at boot, a locked-down egress does not break
  provisioning.

## What this module does NOT do

- **The network** (SNA, networks, routing) — see the `network` module; `network_id` is an input here.
- **The cluster** — see the `cluster` module. Operator access flows *from* this bastion *to*
  cluster nodes; that path is validated where the modules are composed together, not here.
- **Package-level hardening** (fail2ban, `auditd`, `unattended-upgrades`) — deferred to a
  follow-up to keep the module minimal and egress-independent. The base image baseline applies.
- **SSO / federated SSH** (Teleport, IDP-issued certs) and **session recording** — separate
  future stories.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_stackit"></a> [stackit](#requirement\_stackit) | ~> 0.95.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_stackit"></a> [stackit](#provider\_stackit) | ~> 0.95.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [stackit_network_interface.bastion_nic](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/network_interface) | resource |
| [stackit_public_ip.bastion_public_ip](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/public_ip) | resource |
| [stackit_security_group.bastion_sg](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/security_group) | resource |
| [stackit_security_group_rule.egress](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/security_group_rule) | resource |
| [stackit_security_group_rule.icmp](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/security_group_rule) | resource |
| [stackit_security_group_rule.ssh](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/security_group_rule) | resource |
| [stackit_server.bastion](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/server) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bastion_egress_cidrs"></a> [bastion\_egress\_cidrs](#input\_bastion\_egress\_cidrs) | Destination CIDRs the bastion is allowed to reach (egress). One egress rule is created per CIDR. Defaults to empty, which creates no egress rule and leaves STACKIT's default egress posture untouched. | `list(string)` | `[]` | no |
| <a name="input_bastion_icmp_source_cidrs"></a> [bastion\_icmp\_source\_cidrs](#input\_bastion\_icmp\_source\_cidrs) | Source CIDRs allowed to send ICMP echo (ping) to the bastion. One ingress rule is created per CIDR. Leave empty to omit ICMP entirely. | `list(string)` | `[]` | no |
| <a name="input_bastion_image_id"></a> [bastion\_image\_id](#input\_bastion\_image\_id) | STACKIT image UUID for the bastion VM. When null (default), the module auto-resolves the latest Ubuntu 24.04 image. | `string` | `null` | no |
| <a name="input_bastion_ssh_public_keys"></a> [bastion\_ssh\_public\_keys](#input\_bastion\_ssh\_public\_keys) | SSH public keys for the operators authorized to log in. Each key is written to the default user's authorized\_keys via cloud-init. | `list(string)` | n/a | yes |
| <a name="input_bastion_ssh_source_cidrs"></a> [bastion\_ssh\_source\_cidrs](#input\_bastion\_ssh\_source\_cidrs) | Source CIDRs allowed to SSH to the bastion (port 22). One ingress rule is created per CIDR. Must be non-empty. | `list(string)` | n/a | yes |
| <a name="input_boot_volume_size"></a> [boot\_volume\_size](#input\_boot\_volume\_size) | Boot volume size in GiB for the bastion host. | `number` | `20` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name. Used as a prefix for bastion resource names (e.g. cluster\_name + '-bastion', cluster\_name + '-bastion-sg'). | `string` | n/a | yes |
| <a name="input_common_labels"></a> [common\_labels](#input\_common\_labels) | Map of resource labels to apply to all resources that support labelling. | `map(string)` | `{}` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | STACKIT VM flavor for the bastion host. | `string` | `"g2i.1"` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | Network ID for the bastion's NIC. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | STACKIT project ID where the bastion is created. | `string` | n/a | yes |
| <a name="input_public_ip_enabled"></a> [public\_ip\_enabled](#input\_public\_ip\_enabled) | Whether to attach a public IP to the bastion. Set false when the bastion is reached via SNA-internal routing only. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Labels merged into the module-default labels and applied to every taggable bastion resource. STACKIT label keys do not allow ':' — use a separator like '\_' (e.g. solace\_env). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bastion_instance_id"></a> [bastion\_instance\_id](#output\_bastion\_instance\_id) | The bastion server's STACKIT server ID. |
| <a name="output_bastion_private_ip"></a> [bastion\_private\_ip](#output\_bastion\_private\_ip) | The bastion host's private IP address on the cluster network. |
| <a name="output_bastion_public_ip"></a> [bastion\_public\_ip](#output\_bastion\_public\_ip) | The bastion host's public IP address. Null when public\_ip\_enabled is false (SNA-internal access only). |
| <a name="output_bastion_security_group_id"></a> [bastion\_security\_group\_id](#output\_bastion\_security\_group\_id) | ID of the bastion's security group. |
| <a name="output_bastion_username"></a> [bastion\_username](#output\_bastion\_username) | The bastion host's SSH username. |
| <a name="output_ssh_user"></a> [ssh\_user](#output\_ssh\_user) | Alias of bastion\_username, matching the sibling-module output contract. |
<!-- END_TF_DOCS -->
