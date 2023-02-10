# Configuration files -------------------------------------------------------------------------------------------------
data "ignition_file" "nomad_config_master" {
  for_each = var.masters
  path     = "/etc/nomad.d/nomad.hcl"
  mode     = "0744"

  content {
    content = templatefile("${path.module}/templates/nomad.master.hcl", {
      servers       = [for machine_key, machine in var.masters : join(".", [machine_key, var.networks[machine.network].domain])],
      domain        = join(".", [each.key, var.networks[each.value.network].domain]),
      masters_count = length(var.masters)
    })
  }
}

#* The configuration file for Consul
data "ignition_file" "consul_config_master" {
  for_each = var.masters
  path     = "/etc/consul.d/consul.hcl"
  mode     = "0744"

  content {
    content = templatefile("${path.module}/templates/consul.master.hcl", {
      servers = [for machine_key, machine in var.masters : join(".", [machine_key, var.networks[machine.network].domain])],
      domain  = join(".", [each.key, var.networks[each.value.network].domain]),
    })
  }
}
