output "coreos_masters" {
  value = data.ignition_config.coreos_masters
}

output "coreos_slaves" {
  value = data.ignition_config.coreos_slaves
}
