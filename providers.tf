terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.0"
    }

    ignition = {
      source  = "community-terraform-providers/ignition"
      version = "2.1.3"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

provider "local" {}
