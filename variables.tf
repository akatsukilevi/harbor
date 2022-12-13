variable "iso_pool" {
  description = "The pool that will be storing all the downloaded image files"
  default     = "default"
  type        = string
}

variable "disk_pool" {
  description = "The pool that will be storing all the created VM's disk files"
  default     = "default"
  type        = string
}

variable "ssh_key_path" {
  description = "The path to the key to be used for SSH access"
  sensitive   = true
  type        = string
}

variable "auth_password" {
  description = "The password to be used for normal authentication"
  sensitive   = true
  type        = string
}

variable "nomad_version" {
  description = "The Nomad version that will be used"
  type        = string
}

variable "consul_version" {
  description = "The Consul version that will be used"
  type        = string
}

variable "driver_podman_version" {
  description = "The Nomad Podman Driver version that will be used"
  type        = string
}

variable "cni_version" {
  description = "The CNI plugins version that will be used"
  type        = string
}

variable "tls_root_ca" {
  description = "The path to the Consul TLS Root CA file"
  type        = string
  sensitive   = true
}

variable "tls_consul_cert" {
  description = "The path to the Consul TLS Node Certificate file"
  type        = string
  sensitive   = true
}

variable "tls_consul_key" {
  description = "The path to the Consul TLS Node Key file"
  type        = string
  sensitive   = true
}

variable "nomad_master_host" {
  description = "The IP address of the Nomad Master machine"
  type        = string
}

variable "consul_master_host" {
  description = "The IP address of the Consul Master machine"
  type        = string
}

variable "consul_master_key" {
  description = "The encryption key of the Consul Master machine"
  type        = string
  sensitive   = true
}

variable "barebones" {
  description = "The infrastructure that will be set-up on KVM"
  default = {
    machines = {}
    networks = {}
  }

  type = object({
    networks = map(object({
      address = string,
      domain  = string
    })),
    machines = map(object({
      network = string,
      type    = string,
      meta    = map(any)
    }))
  })

  validation {
    condition = alltrue([
      for network in values(var.barebones.networks) : can(cidrnetmask(network.address))
    ])
    error_message = "Networks: Address must be a valid CIDR address"
  }

  validation {
    condition = alltrue([
      for network in values(var.barebones.networks) : can(regex("([a-z0-9]+.)*[a-z0-9]+.[a-z]+", network.domain))
    ])
    error_message = "Networks: Domain must be a valid domain name"
  }
}

variable "kvm" {
  description = "The infrastructure that will be set-up on KVM"
  default = {
    machines = {}
    networks = {}
  }

  type = object({
    networks = map(object({
      mode          = string,
      address       = string,
      domain        = string,
      dns_forwarder = string
    })),
    machines = map(object({
      image    = string,
      network  = string,
      vcpu     = number,
      memoryMB = number,
      diskSize = number,
      type     = string,
      meta     = map(any)
    }))
  })

  validation {
    condition = alltrue([
      for network in values(var.kvm.networks) : network.mode == "nat" || network.mode == "none" || network.mode == "route" || network.mode == "bridge"
    ])
    error_message = "Networks: Only supported networks are: NAT, Route, Bridge & None"
  }

  validation {
    condition = alltrue([
      for network in values(var.kvm.networks) : can(cidrnetmask(network.address))
    ])
    error_message = "Networks: Address must be a valid CIDR address"
  }

  validation {
    condition = alltrue([
      for network in values(var.kvm.networks) : can(regex("([a-z0-9]+.)*[a-z0-9]+.[a-z]+", network.domain))
    ])
    error_message = "Networks: Domain must be a valid domain name"
  }
}
