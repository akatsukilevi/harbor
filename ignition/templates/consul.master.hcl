addresses {
  dns  = "0.0.0.0"
  http = "0.0.0.0"
  https = "0.0.0.0"
  grpc = "0.0.0.0"
  grpc_tls = "0.0.0.0"
}

connect {
  enabled = true
}

acl {
  enabled = false
}

tls {
  defaults {
    verify_incoming = true
    verify_outgoing = true
    ca_file         = "/opt/ssl/root-ca.pem"
    cert_file       = "/opt/ssl/consul_cert.pem"
    key_file        = "/opt/ssl/consul_key.pem"
  }

  internal_rpc {
    verify_server_hostname = false
  }
}

ui_config {
  enabled = true
}

client_addr    = "{{ GetInterfaceIP \"ens3\" }}"
advertise_addr = "{{ GetInterfaceIP \"ens3\" }}"
bind_addr      = "0.0.0.0"

data_dir = "/opt/hashicorp/data/consul"
bootstrap_expect = ${length(servers)}
alt_domain = "consul.${domain}"
server   = true

retry_join = [%{ for machine in setsubtract(servers, [domain]) ~}
  "${ machine }",
%{ endfor ~}]
