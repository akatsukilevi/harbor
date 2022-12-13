#* Generate the CoreOS Ignition configs for the Barebones machines
module "ign_config_barebones" {
  source = "./ignition"

  ssh_key       = file(var.ssh_key_path)
  auth_password = var.auth_password
  machines      = var.barebones.machines
  networks      = var.barebones.networks

  nomad_version         = var.nomad_version
  consul_version        = var.consul_version
  driver_podman_version = var.driver_podman_version
  cni_version           = var.cni_version

  tls_root_ca     = var.tls_root_ca
  tls_consul_cert = var.tls_consul_cert
  tls_consul_key  = var.tls_consul_key

  nomad_master_host  = var.nomad_master_host
  consul_master_host = var.consul_master_host

  consul_master_key = var.consul_master_key
}

resource "local_sensitive_file" "barebones_ign_configs" {
  for_each = var.barebones.machines

  filename = "${path.module}/generated/${each.key}.ign"
  content  = module.ign_config_barebones.coreos[each.key].rendered
}
