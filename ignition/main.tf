#* The full final CoreOS configuration
data "ignition_config" "coreos_masters" {
  for_each = var.masters

  users = [
    data.ignition_user.ign_users_masters[each.key].rendered
  ]

  systemd = [
    # System-related services
    data.ignition_systemd_unit.iscsi.rendered,
    data.ignition_systemd_unit.podman.rendered,

    # Hashistack-related services
    data.ignition_systemd_unit.dependencies_install.rendered,
    data.ignition_systemd_unit.nomad.rendered,
    data.ignition_systemd_unit.consul.rendered
  ]

  files = [
    # System-related files
    data.ignition_file.hostname_masters[each.key].rendered,
    data.ignition_file.zram_generator.rendered,

    # SSL-related files
    data.ignition_file.ssl_root_ca.rendered,
    data.ignition_file.ssl_consul_cert.rendered,
    data.ignition_file.ssl_nomad_cert.rendered,
    data.ignition_file.ssl_consul_key.rendered,
    data.ignition_file.ssl_nomad_key.rendered,

    # Hashistack-related services
    data.ignition_file.consul_config_master[each.key].rendered,
    data.ignition_file.nomad_config_master[each.key].rendered,
    data.ignition_file.hashicorp_install.rendered,
    data.ignition_file.consul_dns.rendered,
  ]
}

data "ignition_config" "coreos_slaves" {
  for_each = var.slaves

  users = [data.ignition_user.ign_users_slaves[each.key].rendered]

  systemd = [
    # System-related services
    data.ignition_systemd_unit.iscsi.rendered,
    data.ignition_systemd_unit.podman.rendered,

    # Hashistack-related services
    data.ignition_systemd_unit.dependencies_install.rendered,
    data.ignition_systemd_unit.nomad.rendered,
    data.ignition_systemd_unit.consul.rendered
  ]

  files = [
    # System-related files
    data.ignition_file.hostname_slaves[each.key].rendered,
    data.ignition_file.zram_generator.rendered,

    # SSL-related files
    data.ignition_file.ssl_root_ca.rendered,
    data.ignition_file.ssl_consul_cert.rendered,
    data.ignition_file.ssl_nomad_cert.rendered,
    data.ignition_file.ssl_consul_key.rendered,
    data.ignition_file.ssl_nomad_key.rendered,

    # Hashistack-related services
    data.ignition_file.consul_config_slave[each.key].rendered,
    data.ignition_file.nomad_config_slave[each.key].rendered,
    data.ignition_file.hashicorp_install.rendered,
    data.ignition_file.consul_dns.rendered,
  ]
}
