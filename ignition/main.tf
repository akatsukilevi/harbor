#* The full final CoreOS configuration
data "ignition_config" "coreos" {
  for_each = var.machines

  users = [data.ignition_user.ign_users[each.key].rendered]

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
    data.ignition_file.hostname[each.key].rendered,
    data.ignition_file.zram_generator.rendered,

    # Hashistack-related services
    data.ignition_file.consul_config[each.key].rendered,
    data.ignition_file.nomad_config[each.key].rendered,
    data.ignition_file.hashicorp_install.rendered,
    data.ignition_file.consul_tls_root.rendered,
    data.ignition_file.consul_tls_cert.rendered,
    data.ignition_file.consul_tls_key.rendered,
    data.ignition_file.consul_dns.rendered,
  ]
}
