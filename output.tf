output "vm_name" {
  value = var.vm_os_type == "linux" ? google_compute_instance.linux_forwarding_vm[0].name : google_compute_instance.windows_forwarding_vm[0].name
}

output "vm_public_ip" {
  value = var.vm_os_type == "linux" ? try(google_compute_instance.linux_forwarding_vm[0].network_interface[0].access_config[0].nat_ip, "N/A") : try(google_compute_instance.windows_forwarding_vm[0].network_interface[0].access_config[0].nat_ip, "N/A")
}

output "internal_load_balancer_name" {
  description = "Internal TCP Load Balancer name"
  value       = google_compute_forwarding_rule.internal_lb.name
}

output "psc_service_attachment_url" {
  description = "Private Service Connect (PSC) service attachment self link"
  value       = google_compute_service_attachment.psc_attachment.self_link
}

output "internal_load_balancer_ip" {
  description = "Internal IP of the Load Balancer"
  value       = google_compute_forwarding_rule.internal_lb.ip_address
}

output "configured_ip_forwarding_rules" {
  description = "List of IP and port forwarding rules"
  value       = var.ip_forwarding_targets
}

output "ssh_key_info" {
  description = "Reminder: SSH key must be managed manually."
  value       = "SSH public key injected via project metadata using ssh_public_key_path"
}
