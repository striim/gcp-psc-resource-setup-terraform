// ---------- variables.tf ----------

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "psc_nat_subnet_name" {
  description = "Name of the pre-created PSC NAT subnet"
  type        = string
}

variable "admin_public_ip" {
  description = "Your public IP address to allow SSH access"
  type        = string
}

variable "base_name" {
  description = "Base name prefix for resources"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the Windows VM"
  type        = string
  default     = ""  # Avoid prompting when not used
}

variable "admin_password" {
  description = "Admin password for the Windows VM"
  type        = string
  sensitive   = true
  default     = ""  # Avoid prompting when not used
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
}

variable "vm_size" {
  description = "Machine type for the VM (e.g., e2-medium)"
  type        = string
}

variable "vm_image" {
  description = "Image to use for the VM (e.g., debian-cloud/debian-11)"
  type        = string
}

variable "ip_forwarding_targets" {
  description = "List of target IPs and ports for forwarding"
  type = list(object({
    ip   = string
    port = number
  }))
}

variable "vm_os_type" {
  description = "Operating system type (linux or windows)"
  type        = string
  validation {
    condition     = contains(["linux", "windows"], var.vm_os_type)
    error_message = "Valid values are 'linux' or 'windows'."
  }
}

variable "enable_nat_ip" {
  description = "Whether to assign a public IP (NAT) to the VM"
  type        = bool
  default     = true
}

variable "psc_consumer_projects" {
  description = "List of project IDs allowed to auto-connect via Private Service Connect"
  type        = list(string)
}
