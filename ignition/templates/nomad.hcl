data_dir      = "/opt/hashicorp/data/nomad"
bind_addr     = "0.0.0.0"
enable_syslog = true

client {
  enabled = true
  servers = ["${master_host}"]

  node_class = "${node_class}"
  meta = {
    % { for key, value in meta~}
    $ { key } = "${value}"
    % { endfor~}
  }
}

acl {
  enabled    = true
  token_ttl  = "30s"
  policy_ttl = "60s"
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
