data_dir      = "/opt/hashicorp/data/nomad"
bind_addr     = "0.0.0.0"
enable_syslog = true

acl {
  enabled    = false
}

client {
  enabled = true

  servers = [
	%{ for machine in servers ~}
	"${ machine }",
	%{ endfor ~}
  ]

  meta {
	%{ for key, value in meta ~}
	${key} = ${value}
	%{ endfor ~}
  }
}

tls {
  http = true
  rpc = true

  ca_file         = "/opt/ssl/root-ca.pem"
  cert_file       = "/opt/ssl/nomad_cert.pem"
  key_file        = "/opt/ssl/nomad_key.pem"
}

plugin "docker" {
  config {
    extra_labels = ["job_name", "job_id", "task_group_name", "task_name", "namespace", "node_name", "node_id"]

    gc {
      image       = true
      image_delay = "3m"
      container   = true

      dangling_containers {
        enabled        = true
        dry_run        = false
        period         = "5m"
        creation_grace = "5m"
      }
    }

    volumes {
      enabled      = true
      selinuxlabel = "z"
    }

    allow_privileged = true
    allow_caps       = ["chown", "net_raw"]
  }
}
