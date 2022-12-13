#* Generate the CoreOS Ignition configs for the KVM machines
module "ign_config_kvm" {
  source = "./ignition"

  ssh_key       = file(var.ssh_key_path)
  auth_password = var.auth_password
  machines      = var.kvm.machines
  networks      = var.kvm.networks

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

#* Provision all the networks mentioned on `kvm.networks`
resource "libvirt_network" "nat" {
  for_each  = var.kvm.networks
  name      = each.key
  mode      = each.value.mode
  addresses = [each.value.address]

  domain = each.value.domain

  dns {
    enabled    = true
    local_only = false
    forwarders { address = each.value.dns_forwarder }
  }

  dhcp { enabled = true }
  autostart = true
}

#* Provision all the disks for the machines mentioned on `kvm.machines`
resource "libvirt_volume" "machine_image" {
  for_each = var.kvm.machines

  name             = join("_", [each.key, "storage"])
  base_volume_name = each.value.image
  pool             = var.disk_pool
  size             = each.value.diskSize * 1000000
}

//* Provision all the CoreOS configuration for the machines mentioned on `kvm.machines`
resource "libvirt_ignition" "coreos_config" {
  for_each = var.kvm.machines

  name    = join("_", ["config", join(".", [each.key, "ign"])])
  content = module.ign_config_kvm.coreos[each.key].rendered
}

//* Creates the machine themselves
resource "libvirt_domain" "machine" {
  for_each = var.kvm.machines

  name   = each.key
  memory = each.value.memoryMB
  vcpu   = each.value.vcpu

  coreos_ignition = libvirt_ignition.coreos_config[each.key].id

  #* It expects to have the default KVM network created for host-guest communications
  network_interface {
    network_name   = "default"
    hostname       = join(".", [each.key, var.kvm.networks[each.value.network].domain])
    wait_for_lease = true
  }

  #* The custom network requested by the machine
  network_interface {
    network_id     = libvirt_network.nat[each.value.network].id
    hostname       = join(".", [each.key, var.kvm.networks[each.value.network].domain])
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.machine_image[each.key].id
  }

  #* We attach a serial for ease-of-maintenance
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  #* SPICE-based graphics, should be disabled?
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = "true"
  }
}
