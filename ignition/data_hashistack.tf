# Configuration files -------------------------------------------------------------------------------------------------

#* The main bootstrap script for the Hashistack and dependencies
data "ignition_file" "hashicorp_install" {
  path = "/usr/local/bin/install-hashicorp.sh"
  mode = "0755"

  content {
    content = templatefile("${path.module}/templates/install-hashicorp.sh", {
      nomad_version         = var.nomad_version,
      consul_version        = var.consul_version,
      driver_podman_version = var.driver_podman_version,
      cni_version           = var.cni_version
    })
  }
}

#* The configuration file for Nomad
data "ignition_file" "nomad_config" {
  for_each = var.machines
  path     = "/etc/nomad.d/nomad.hcl"
  mode     = "0744"

  content {
    content = templatefile("${path.module}/templates/nomad.hcl", {
      master_host = var.nomad_master_host,
      meta        = each.value.meta,
      node_class  = each.value.type
    })
  }
}

#* The configuration file for Consul
data "ignition_file" "consul_config" {
  for_each = var.machines
  path     = "/etc/consul.d/consul.hcl"
  mode     = "0744"

  content {
    content = templatefile("${path.module}/templates/consul.hcl", {
      domain      = join(".", [each.key, var.networks[each.value.network].domain]),
      master_host = var.consul_master_host,
      master_key  = var.consul_master_key,
      meta        = each.value.meta,
    })
  }
}

#* The Consul TLS Certificate Authority
data "ignition_file" "consul_tls_root" {
  path = "/opt/ssl/root-ca.pem"
  mode = "0755"

  content {
    content = file(var.tls_root_ca)
  }
}

#* The Consul TLS Certificate file
data "ignition_file" "consul_tls_cert" {
  path = "/opt/ssl/consul_cert.pem"
  mode = "0755"

  content {
    content = file(var.tls_consul_cert)
  }
}

#* The Consul TLS Key file
data "ignition_file" "consul_tls_key" {
  path = "/opt/ssl/consul_key.pem"
  mode = "0755"

  content {
    content = file(var.tls_consul_key)
  }
}

#* Enables Consul Forward DNS Resolution on the local machine
data "ignition_file" "consul_dns" {
  path = "/etc/systemd/resolved.conf.d/consul.conf"
  mode = "0644"
  content {
    content = <<EOL
[Resolve]
DNS=127.0.0.1:8600
DNSSEC=false
Domains=~consul
EOL
  }
}

# Services ------------------------------------------------------------------------------------------------------------

#* Service responsible for installing the Hashistack binaries
data "ignition_systemd_unit" "dependencies_install" {
  name    = "hashicorp-install.service"
  content = file("${path.module}/services/hashicorp-install.service")
}

#* The Nomad instance service
data "ignition_systemd_unit" "nomad" {
  name    = "nomad.service"
  enabled = true
  content = file("${path.module}/services/nomad.service")
}

#* The Consul instance service
data "ignition_systemd_unit" "consul" {
  name    = "consul.service"
  enabled = true
  content = file("${path.module}/services/consul.service")
}
