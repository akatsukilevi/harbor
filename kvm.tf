#* Generate the CoreOS Ignition configs for the KVM machines
module "ign_config_kvm" {
  source = "./ignition"

  ssh_key  = file(var.ssh_key_path)
  networks = var.kvm.networks
  masters  = var.kvm.masters
  slaves   = var.kvm.slaves

  nomad_version         = var.nomad_version
  consul_version        = var.consul_version
  driver_podman_version = var.driver_podman_version
  cni_version           = var.cni_version
}

#* Provision all the networks
resource "libvirt_network" "networks" {
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

#* Provision all the disks for the machines
resource "libvirt_volume" "images_masters" {
  for_each = var.kvm.masters

  base_volume_name = var.coreos_image
  base_volume_pool = var.coreos_image_pool
  name             = join("_", [each.key, "storage"])
  pool             = var.disk_pool
  size             = each.value.diskSize * 1000000
}

resource "libvirt_volume" "images_slaves" {
  for_each = var.kvm.slaves

  base_volume_name = var.coreos_image
  base_volume_pool = var.coreos_image_pool
  name             = join("_", [each.key, "storage"])
  pool             = var.disk_pool
  size             = each.value.diskSize * 1000000
}

//* Provision all the CoreOS configuration for the machines
resource "libvirt_ignition" "coreos_masters" {
  for_each = var.kvm.masters

  name    = join("_", ["config", join(".", [each.key, "ign"])])
  content = module.ign_config_kvm.coreos_masters[each.key].rendered
}

resource "libvirt_ignition" "coreos_slaves" {
  for_each = var.kvm.slaves

  name    = join("_", ["config", join(".", [each.key, "ign"])])
  content = module.ign_config_kvm.coreos_slaves[each.key].rendered
}

//* Creates the machine themselves
resource "libvirt_domain" "machines_masters" {
  for_each = var.kvm.masters

  name   = each.key
  memory = each.value.memoryMB
  vcpu   = each.value.vcpu

  coreos_ignition = libvirt_ignition.coreos_masters[each.key].id

  # Attach the required network interface
  network_interface {
    network_id     = libvirt_network.networks[each.value.network].id
    hostname       = join(".", [each.key, var.kvm.networks[each.value.network].domain])
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.images_masters[each.key].id
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

resource "libvirt_domain" "machines_slaves" {
  for_each = var.kvm.slaves

  name   = each.key
  memory = each.value.memoryMB
  vcpu   = each.value.vcpu

  coreos_ignition = libvirt_ignition.coreos_slaves[each.key].id

  # Attach the required network interface
  network_interface {
    network_id     = libvirt_network.networks[each.value.network].id
    hostname       = join(".", [each.key, var.kvm.networks[each.value.network].domain])
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.images_slaves[each.key].id
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
