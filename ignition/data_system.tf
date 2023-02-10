# Configuration Files -------------------------------------------------------------------------------------------------
#* Configure the hostname of the machine
data "ignition_file" "hostname_masters" {
  for_each = var.masters
  path     = "/etc/hostname"
  mode     = "0420"

  content {
    content = join(".", [each.key, var.networks[each.value.network].domain])
  }
}

data "ignition_file" "hostname_slaves" {
  for_each = var.slaves
  path     = "/etc/hostname"
  mode     = "0420"

  content {
    content = join(".", [each.key, var.networks[each.value.network].domain])
  }
}

#* Enables SWAP-On-ZRAM for better stability
data "ignition_file" "zram_generator" {
  path = "/etc/systemd/zram-generator.conf"
  mode = "0644"
  content {
    content = "[zram0]"
  }
}

# Services ------------------------------------------------------------------------------------------------------------
#* Enables the Podman connection socket for use of containers
data "ignition_systemd_unit" "podman" {
  name    = "podman.socket"
  enabled = true
}

#* Enables use of iSCSI devices on the server
data "ignition_systemd_unit" "iscsi" {
  name    = "iscsi.service"
  enabled = true
}

# Users ---------------------------------------------------------------------------------------------------------------
#* The main user on the server itself
data "ignition_user" "ign_users_masters" {
  for_each            = var.masters
  name                = each.key
  groups              = ["docker", "wheel", "sudo"]
  ssh_authorized_keys = [var.ssh_key]
}

data "ignition_user" "ign_users_slaves" {
  for_each            = var.slaves
  name                = each.key
  groups              = ["docker", "wheel", "sudo"]
  ssh_authorized_keys = [var.ssh_key]
}
