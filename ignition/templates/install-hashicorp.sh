#!/bin/bash -e
URL=https://releases.hashicorp.com
CNI=https://github.com/containernetworking/plugins

# Download binaries & drivers
curl -sL $${URL}/nomad/${nomad_version}/nomad_${nomad_version}_linux_amd64.zip --output /var/local/nomad.zip
curl -sL $${URL}/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip --output /var/local/consul.zip
curl -sL $${URL}/nomad-driver-podman/${driver_podman_version}/nomad-driver-podman_${driver_podman_version}_linux_amd64.zip --output /var/local/nomad-driver-podman.zip

# Extract all required files
podman run -it --rm -v /var/local:/mnt:Z -w /mnt docker.io/library/busybox unzip nomad.zip
podman run -it --rm -v /var/local:/mnt:Z -w /mnt docker.io/library/busybox unzip consul.zip
podman run -it --rm -v /var/local:/mnt:Z -w /mnt docker.io/library/busybox unzip nomad-driver-podman.zip

# Cleanup ZIP files
rm -f /var/local/{nomad,nomad-driver-podman,consul}.zip

# Move all binaries into their proper places
mv /var/local/nomad /usr/local/bin/
mv /var/local/consul /usr/local/bin/

# Add capabilities to the binaries
chcon -t bin_t /usr/local/bin/nomad
chcon -t bin_t /usr/local/bin/consul

# Move & Setup the Podman Driver into place
mkdir -p /opt/hashicorp/data/nomad/plugins
mv /var/local/nomad-driver-podman /opt/hashicorp/data/nomad/plugins/
chcon -t bin_t /opt/hashicorp/data/nomad/plugins/nomad-driver-podman

# Create CNI path structure
mkdir -p /opt/cni/bin

# Download CNI
curl -sL $${CNI}/releases/download/v${cni_version}/cni-plugins-linux-amd64-v${cni_version}.tgz --output /opt/cni/bin/binaries.tgz

# Extract them
podman run -it --rm -v /opt/cni/bin:/mnt:Z -w /mnt docker.io/library/busybox tar -xzvf binaries.tgz

# Cleanup
rm -f /opt/cni/bin/binaries.tgz

# Configure firewall to enable the required ports
# For Nomad, see: https://developer.hashicorp.com/nomad/docs/install/production/requirements#ports-used
# For Consul, see: https://developer.hashicorp.com/consul/docs/install/ports

sudo iptables -A INPUT -p tcp --dport 4600 -j ACCEPT # Nomad HTTP API
sudo iptables -A INPUT -p tcp --dport 4607 -j ACCEPT # Nomad RPC
sudo iptables -A INPUT -p tcp --dport 4648 -j ACCEPT # Nomad Serf WAN (TCP)
sudo iptables -A INPUT -p udp --dport 4648 -j ACCEPT # Nomad Serf WAN (UDP)

sudo iptables -A INPUT -p tcp --dport 8600 -j ACCEPT # Consul DNS server (TCP)
sudo iptables -A INPUT -p udp --dport 8600 -j ACCEPT # Consul DNS server (UDP)
sudo iptables -A INPUT -p tcp --dport 8500 -j ACCEPT # Consul HTTP API
sudo iptables -A INPUT -p tcp --dport 8301 -j ACCEPT # Consul LAN Serf (TCP)
sudo iptables -A INPUT -p udp --dport 8301 -j ACCEPT # Consul LAN Serf (UDP)
sudo iptables -A INPUT -p tcp --dport 8300 -j ACCEPT # Consul RPC
sudo iptables -A INPUT -p tcp --match multiport --dports 21000:21255 -j ACCEPT # Consul Sidecar (TCP)
sudo iptables -A INPUT -p udp --match multiport --dports 21000:21255 -j ACCEPT # Consul Sidecar (UDP)

sudo iptables-save

# Mark the binaries as installed
mkdir -p /var/log/provision-done
touch /var/log/provision-done/install-hashicorp
