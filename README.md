# Harbor

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

A Infrastructure-as-Code Provisioner for creating a cluster of Fedora CoreOS machines running the Hashistack to quickly get up and running both in development and production.

Made by [SigaMeCar](https://www.sigamecar.com.br) with love for the OSS community.

## Getting Started

To get started, you need the server machines already running, as at the moment this provisioner only creates the client machines. In future, it will be able to provision both server and client machines.

### Prerequisites

- [Nomad](https://www.nomadproject.io)
- [Consul](https://www.consul.io)
- [Terraform](https://www.terraform.io)

# Setup

Before starting, you need to do a few steps:

## Generate the SSH key

For accessing the machines via SSH, you need to generate a new SSH key:

```bash
$ ssh-keygen -f path/to/ssh/key
```

If you already have a SSH key you'd like to use, you can continue without generating a new one

## Configure KVM

> **Note:** This step is optional if you are deploying barebones configurations, but required if you are deploying KVM machines.

This configuration runs on the assumption that:

### You have Fedora CoreOS qcow2 file already stored on the default pool ready to provision the other machines automatically

> **Note:** To download the CoreOS qcow2, please visit the [CoreOS Download Page](https://getfedora.org/en/coreos/download/). Make sure to download the virtualized QEMU entry.

### Your host machine firewall does not block `Host <-> Guest` communications.

> **For future reference:** Some FirewallD distros does block it by default, check your libvirt rules in case of communication errors such as `Connection Refused`.

If you have a fresh installed KVM setup, you already have it, you can check this via:

```bash
$ virsh net-info default
Name:           default
UUID:           f63c210f-67e7-4aed-8d21-066d9fd6c7d6
Active:         no
Persistent:     yes
Autostart:      no
Bridge:         virbr0
```

If the default network is missing, create `/tmp/default.xml` with the following contents. (Optionally, use [DHCP host entries](https://jamielinux.com/docs/libvirt-networking-handbook/appendix/dhcp-host-entries.html) to always assign the same IP address to a particular VM.)

```xml
<network>
  <name>default</name>
  <bridge name="virbr0"/>
  <forward mode="nat"/>
  <ip address="192.168.122.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.122.2" end="192.168.122.254"/>
    </dhcp>
  </ip>
</network>
```

Use `/tmp/default.xml` to create the default network.

```bash
$ sudo virsh net-define /tmp/default.xml
$ sudo virsh net-start default
$ sudo virsh net-autostart default
```

> Source: [NAT-based network - libvirt Networking Handbook](https://jamielinux.com/docs/libvirt-networking-handbook/nat-based-network.html) by Jamie Nguyen

## Create the configuration

Create a `config.tfvars` file following the template below:

```tf
ssh_key_path = "path/to/ssh/key" # The SSH key that will be put on `.ssh/authorized_keys`

nomad_version         = "1.4.3" # Check Nomad website for the latest version
consul_version        = "1.14.1" # Check Consul website for the latest version
driver_podman_version = "0.4.1" # Check https://github.com/hashicorp/nomad-driver-podman for latest version
cni_version           = "1.1.1" # Check https://github.com/containernetworking/plugins for latest version

coreos_image      = "coreos.qcow2" # The name of the CoreOS image that will be used, can be ignored if using barebones only
coreos_image_pool = "default" # The pool that the CoreOS image can be found at, can be ignored if using barebones only

# OPTIONAL: Can be omitted if you'd like to only run through KVM
barebones = {
  networks = {
    "my_prod_network" = {
		  address = "10.0.0.1/24", # Must be a valid CIDR identifying the network
		  domain = "production.local" # The root domain for the machines
	  }
  }

  masters = {
    "barebones_masters_alpha" = {
      network  = "main_net",  # The network name as defined on `barebones.networks`
    }
  }

  slaves = {
    "barebones_slaves_alpha" = {
      network  = "main_net",  # The network name as defined on `barebones.networks`
      meta    = { my_key = "my_value" } # Any custom metadata you'd like to define on the machine
    }
  }
}

# OPTIONAL: Can be omitted if you'd like to only run through Barebones
kvm = {
  networks = {
    "my_dev_network" = {
      mode = "nat", # KVM Network mode, supports NAT, Route, Bridge & None
      address = "10.0.10.1/24", # Valid CIDR identifying the network, will be used to give the IP address to each machine
      domain = "development.local", # The root domain for the machines
      dns_forwarder = "1.1.1.1" # The fallback DNS if Consul cannot resolve a DNS lookup
    },
  }

  masters = {
    "kvm_masters_alpha" = {
      network  = "my_dev_network", # The network name as defined on `kvm.networks`
      vcpu     = 2, # How many vCPU's will be issued for the machine
      memoryMB = 2 * 1024, # How much memory the machine will have (in MB)
      diskSize = 50 * 1024, # How much disk storage the machine will have (in MB)
    },
  }

  slaves = {
    "kvm_slaves_alpha" = {
      network  = "my_dev_network", # The network name as defined on `kvm.networks`
      vcpu     = 2, # How many vCPU's will be issued for the machine
      memoryMB = 2 * 1024, # How much memory the machine will have (in MB)
      diskSize = 50 * 1024, # How much disk storage the machine will have (in MB)
      meta    = { my_key = "my_value" } # Any custom metadata you'd like to define on the machine
    },
  }
}
```

# Usage

To use it, you can plan and apply through normal means:

```bash
$ terraform plan -var-file=path/to/local.tfvars # Plan the deployment according to your configuration file
$ terraform apply -var-file=path/to/local.tfvars # Apply the deployment according to your configuration file
```

If you use barebones instead of KVM, the generated `.ign` files can be found at `generated`.

# Clean-up

To clean-up everything, you can simply run:

```bash
$ terraform destroy -var-file=path/to/local.tfvars
```

> **Note:** When using barebones, it will delete the generated files in the `generated` folder. Make sure it is fine to delete theses files before continuing.

## Built With

- [Contributor Covenant](https://www.contributor-covenant.org/) - Used for the Code of Conduct
- [Terraform Ignition Provider](https://github.com/community-terraform-providers/terraform-provider-ignition) - Used for generating the Fedora CoreOS configuration dynamically
- [Terraform libvirt Provider](https://github.com/dmacvicar/terraform-provider-libvirt) - Used for interacting and provisioning with libvirt for generating the VM's
- [Terraform local Provider](https://github.com/hashicorp/terraform-provider-local) - Used for saving the generated barebones ignition configuration

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

- [**Felipe Angelo Sgarbi**](https://github.com/akatsukilevi) - _Main Developer of project_
- [**SigaMeCar**](https://www.sigamecar.com.br) - _Infrastructure & Main Company behind project_
- [**Billie Thompson**](https://github.com/PurpleBooth) - _Provided README Template_

See also the list of [contributors](https://github.com/akatsukilevi/harbor/contributors) who participated in this project.

## License

This project is licensed under the GNU General Public License v3.0 License - see the [LICENSE.md](LICENSE.md) file for details
