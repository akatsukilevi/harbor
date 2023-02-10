data_dir      = "/opt/hashicorp/data/nomad"
bind_addr     = "0.0.0.0"
enable_syslog = true

acl {
  enabled    = true
  token_ttl  = "30s"
  policy_ttl = "60s"
}

server {
  enabled          = true
  bootstrap_expect = ${masters_count}

  server_join {
    retry_join = [
      %{ for machine in setsubtract(servers, [domain]) ~}
      "${ machine }",
      %{ endfor ~}
    ]
    retry_max = 3
    retry_interval = "15s"
  }
}

tls {
  http = true
  rpc = true

  ca_file         = "/opt/ssl/root-ca.pem"
  cert_file       = "/opt/ssl/nomad_cert.pem"
  key_file        = "/opt/ssl/nomad_key.pem"
}
