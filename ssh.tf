#resource "google_compute_project_metadata_item" "ssh_keys" {
#  count = var.vm_os_type == "linux" ? 1 : 0
#  key   = "ssh-keys"
#  value = "${var.admin_username}:${file(var.ssh_public_key_path)}"
#
#  lifecycle {
#    ignore_changes = [value]
#  }
#}
