output "kvm_machines_masters" {
  description = "The machines generated on libvirt"
  value       = libvirt_domain.machines_masters.*
}

output "kvm_machines_slaves" {
  description = "The machines generated on libvirt"
  value       = libvirt_domain.machines_slaves.*
}

output "barebones_machines" {
  description = "The machines generated for barebones"
  sensitive   = true
  value = flatten([
    [for machine_key, machine in var.barebones.masters : {
      "${machine_key}" = local_sensitive_file.barebones_ign_masters
    }],
    [for machine_key, machine in var.barebones.slaves : {
      "${machine_key}" = local_sensitive_file.barebones_ign_slaves
    }],
  ])
}
