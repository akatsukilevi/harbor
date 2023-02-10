variable "networks" {
  default = {}
  type = map(object({
    domain = string,
  }))
}

variable "masters" {
  default = {}
  type = map(object({
    network = string
  }))
}

variable "slaves" {
  default = {}
  type = map(object({
    network = string,
    meta    = map(any)
  }))
}

variable "ssh_key" {
  description = "The key to be used for SSH access"
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

variable "coreos_channel" {
  description = "The Channel of CoreOS release that will be fetched"
  type        = string
  default     = "stable"
}
