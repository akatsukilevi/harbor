#* Generate the CoreOS Ignition configs for the Barebones machines
module "ign_config_barebones" {
  source = "./ignition"

  ssh_key  = file(var.ssh_key_path)
  networks = var.barebones.networks
  masters  = var.barebones.masters
  slaves   = var.barebones.slaves

  nomad_version         = var.nomad_version
  consul_version        = var.consul_version
  driver_podman_version = var.driver_podman_version
  cni_version           = var.cni_version
}

resource "local_sensitive_file" "barebones_ign_masters" {
  for_each = var.barebones.masters

  filename = "${path.module}/generated/master_${each.key}.ign"
  content  = module.ign_config_barebones.coreos_masters[each.key].rendered
}

resource "local_sensitive_file" "barebones_ign_slaves" {
  for_each = var.barebones.slaves

  filename = "${path.module}/generated/master_${each.key}.ign"
  content  = module.ign_config_barebones.coreos_slaves[each.key].rendered
}
