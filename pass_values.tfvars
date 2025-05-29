project_id     = "<your_project_name>"                              # ✅ Replace with your GCP project ID
region         = "<region>>"                                        # ✅ GCP region
zone           = "<zone>"                                           # ✅ GCP zone

vpc_name       = "<vpc-name>"                                       # ✅ Name of your VPC
subnet_name    = "<subnet_name>"                                    # ✅ Name of your subnet
psc_nat_subnet_name = "<psc_subnet_name>"                           # ✅ Pre-created PSC NAT subnet name

admin_public_ip = "00.00.00.00/32"                                  # ✅ IP to allow SSH access
base_name       = "striim-int"                                      # ✅ Base name prefix
admin_username  = "gcpuser"                                         # ✅ SSH username
ssh_public_key_path = "~/.ssh/id_rsa.pub"                           # ✅ Path to your public SSH key file. Change path accordingly

vm_size    = "e2-standard-2"                                        # ✅ GCP machine type. Check if require

# ✅ OS Type: Choose only one
#vm_os_type = "linux"                                               # ✅ Use this for Linux VM
#vm_image   = "ubuntu-os-cloud/ubuntu-2004-focal-v20240808"         # ✅ Use this for Ubuntu 20.04 Image. Change if require 

vm_os_type = "windows"                                              # ✅ Use this for Windows VM
vm_image = "windows-cloud/windows-server-2025-dc-v20250515"         # ✅ Use this for Windows Server 2019 Image. Change if require

# ✅ Enable public IP (set to false for private-only VM)
enable_nat_ip = true                                                # ✅ Change to false, if you don't want to add public IP to the VM

# ✅ Whitelisted consumer projects for PSC auto-accept
psc_consumer_projects = [
  "<gcp_project_id>"                                                # ✅ Add allowed gcp project IDs to create psc endpoint
]

# ✅ List your target IPs and ports to configure NAT-style forwarding
ip_forwarding_targets = [                                           # ✅ Add your target database IPs and Ports to create IP forwarding rules
  { ip = "192.168.0.1", port = 1433 },
  { ip = "192.168.0.2", port = 1435 },
  { ip = "192.168.0.3", port = 1438 },
  { ip = "192.168.0.4", port = 1440 }
]
