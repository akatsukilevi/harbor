variable "networks" {
  default = {}
  type = map(object({
    domain = string,
  }))
}

variable "machines" {
  default = {}
  type = map(object({
    network = string,
    type    = string,
    meta    = map(any)
  }))
}

variable "ssh_key" {
  description = "The key to be used for SSH access"
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
