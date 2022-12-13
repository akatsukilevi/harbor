output "kvm_machines" {
  description = "The machines generated on libvirt"
  value       = libvirt_domain.machine.*
}

output "barebones_machines" {
  description = "The machines generated for barebones"
  sensitive   = true
  value = flatten([
    for machine_key, machine in var.barebones.machines : {
      "${machine_key}" = local_sensitive_file.barebones_ign_configs
    }
  ])
}
