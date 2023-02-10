# Configuration files -------------------------------------------------------------------------------------------------
data "ignition_file" "nomad_config_slave" {
  for_each = var.slaves
  path     = "/etc/nomad.d/nomad.hcl"
  mode     = "0744"

  content {
    content = templatefile("${path.module}/templates/nomad.slave.hcl", {
      servers = [for machine_key, machine in var.masters : join(".", [machine_key, var.networks[machine.network].domain])],
      meta    = each.value.meta
    })
  }
}

#* The configuration file for Consul
data "ignition_file" "consul_config_slave" {
  for_each = var.slaves
  path     = "/etc/consul.d/consul.hcl"
  mode     = "0744"

  content {
    content = templatefile("${path.module}/templates/consul.slave.hcl", {
      servers = [for machine_key, machine in var.masters : join(".", [machine_key, var.networks[machine.network].domain])],
      domain  = join(".", [each.key, var.networks[each.value.network].domain])
    })
  }
}
