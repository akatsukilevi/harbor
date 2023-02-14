# TLS -----------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "hashistack_key" {
  algorithm = "RSA"
}

resource "tls_private_key" "nomad_key" {
  algorithm = "RSA"
}

resource "tls_private_key" "consul_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "hashistack_root_ca" {
  private_key_pem       = tls_private_key.hashistack_key.private_key_pem
  validity_period_hours = 30 * 24 # 1 month

  subject {
    common_name = "Harbor HashiStack"
  }

  is_ca_certificate = true

  # ! This possibly could be limited down to what Nomad/Consul actually uses. Feels like it could be a security issue?
  allowed_uses = ["any_extended"]
}

resource "tls_cert_request" "nomad_crt" {
  private_key_pem = tls_private_key.nomad_key.private_key_pem

  subject {
    organization = "Harbor HashiStack - Nomad"
  }
}

resource "tls_cert_request" "consul_crt" {
  private_key_pem = tls_private_key.consul_key.private_key_pem

  subject {
    organization = "Harbor HashiStack - Consul"
  }
}

resource "tls_locally_signed_cert" "nomad_cert" {
  cert_request_pem      = tls_cert_request.nomad_crt.cert_request_pem
  ca_private_key_pem    = tls_private_key.hashistack_key.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.hashistack_root_ca.cert_pem
  validity_period_hours = 30 * 24 # 1 month

  # ! This possibly could be limited down to what Nomad/Consul actually uses. Feels like it could be a security issue?
  allowed_uses = ["any_extended"]
}

resource "tls_locally_signed_cert" "consul_cert" {
  cert_request_pem      = tls_cert_request.consul_crt.cert_request_pem
  ca_private_key_pem    = tls_private_key.hashistack_key.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.hashistack_root_ca.cert_pem
  validity_period_hours = 30 * 24 # 1 month

  # ! This possibly could be limited down to what Nomad/Consul actually uses. Feels like it could be a security issue?
  allowed_uses = ["any_extended"]
}

# Files ---------------------------------------------------------------------------------------------------------------

# Hashistack Environment Variables
data "ignition_file" "hashistack_environment" {
  path      = "/etc/environment"
  mode      = "0644"
  overwrite = true

  content {
    content = <<EOL
export NOMAD_ADDR="https://127.0.0.1:4646"
export CONSUL_HTTP_ADDR="https://127.0.0.1:8500"

export NOMAD_HTTP_SSL=true
export CONSUL_HTTP_SSL=true

export NOMAD_HTTP_SSL_VERIFY=false
export CONSUL_HTTP_SSL_VERIFY=false

export NOMAD_SKIP_VERIFY=true
export CONSUL_SKIP_VERIFY=true

export NOMAD_CACERT=/opt/ssl/root-ca.pem
export CONSUL_CACERT=/opt/ssl/root-ca.pem

export NOMAD_CLIENT_CERT=/opt/ssl/nomad_cert.pem
export NOMAD_CLIENT_KEY=/opt/ssl/nomad_key.pem

export CONSUL_CLIENT_CERT=/opt/ssl/consul_cert.pem
export CONSUL_CLIENT_KEY=/opt/ssl/consul_key.pem
EOL
  }
}

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

# /opt/ssl/root-ca.pem
data "ignition_file" "ssl_root_ca" {
  path = "/opt/ssl/root-ca.pem"
  mode = "0644"

  content {
    content = tls_self_signed_cert.hashistack_root_ca.cert_pem
  }
}

# /opt/ssl/nomad_cert.pem
data "ignition_file" "ssl_nomad_cert" {
  path = "/opt/ssl/nomad_cert.pem"
  mode = "0644"

  content {
    content = tls_locally_signed_cert.nomad_cert.cert_pem
  }
}

# /opt/ssl/nomad_key.pem
data "ignition_file" "ssl_nomad_key" {
  path = "/opt/ssl/nomad_key.pem"
  mode = "0644"

  content {
    content = tls_private_key.nomad_key.private_key_pem
  }
}

# /opt/ssl/consul_cert.pem
data "ignition_file" "ssl_consul_cert" {
  path = "/opt/ssl/consul_cert.pem"
  mode = "0644"

  content {
    content = tls_locally_signed_cert.consul_cert.cert_pem
  }
}

# /opt/ssl/consul_key.pem
data "ignition_file" "ssl_consul_key" {
  path = "/opt/ssl/consul_key.pem"
  mode = "0644"

  content {
    content = tls_private_key.consul_key.private_key_pem
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
