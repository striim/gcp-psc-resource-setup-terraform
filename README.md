
# ⚡ GCP IP Forwarding with PSC & Load Balancer (Terraform Module)

This Terraform script provisions a flexible GCP setup for port forwarding via Linux or Windows VMs with support for:

- 🔀 IP forwarding with dynamic NAT rules
- 🔐 RDP/SSH access based on OS
- ⚖️ Internal TCP Load Balancer
- 🔌 Private Service Connect (PSC) service attachment

> ⚠️ This script creates billable resources in your GCP account. Please review carefully before applying.

---

## ✅ Prerequisites

Before you run this module:

1. A GCP project with **billing enabled**
2. Required APIs activated:
   - `compute.googleapis.com`
   - `servicenetworking.googleapis.com`
3. Values set in `pass_values.tfvars`, including:
   - VPC name, subnet name
   - OS type: `linux` or `windows`
   - `ip_forwarding_targets`: list of `{ ip, port }` objects
4. Optional: SSH public key for Linux access

---

## ⚙️ Setup Instructions

### 1️⃣ Initialize
```bash
terraform init
```

### 2️⃣ Preview changes
```bash
terraform plan -var-file="pass_values.tfvars"
```

### 3️⃣ Apply the script
```bash
terraform apply -var-file="pass_values.tfvars" -auto-approve
```

---

## 🚀 Outputs

- `vm_name` – Compute VM name
- `vm_public_ip` – NAT IP (if enabled)
- `internal_load_balancer_name` – TCP LB name
- `psc_service_attachment_url` – PSC attachment URL
- `ssh_key_info` – Reminder about SSH key use

---

## 🧹 Cleanup

To destroy all resources:
```bash
terraform destroy -var-file="pass_values.tfvars" -auto-approve
```

---

## 🛠️ Troubleshooting & Useful Commands

### Linux VM

#### SSH into VM
```bash
ssh -i ~/.ssh/<your-key> <admin_username>@<vm_public_ip>
```

#### Show NAT rules
```bash
sudo iptables -t nat -nvL
```

#### Manually forward a port
```bash
sudo iptables -t nat -A PREROUTING -p tcp --dport <SRC_PORT> -j DNAT --to-destination <DEST_IP>:<DST_PORT>
sudo iptables -t nat -A POSTROUTING -p tcp -d <DEST_IP> --dport <DST_PORT> -j SNAT --to-source $(hostname -i)
sudo iptables-save
```

---

### Windows VM

#### Show port forwarding rules
```powershell
netsh interface portproxy show all
```

#### Add forwarding rule
```powershell
netsh interface portproxy add v4tov4 listenport=<PORT> listenaddress=0.0.0.0 connectport=<PORT> connectaddress=<DEST_IP>
```

#### View log
```powershell
type C:\portproxy.log
```

---

## 🧠 Notes

- Port forwarding rules are passed as `ip_forwarding_targets`:
  ```hcl
  ip_forwarding_targets = [
    { ip = "192.168.0.1", port = 1433 },
    { ip = "192.168.0.2", port = 1435 },
  ]
  ```
- First port is used in the Load Balancer health check.
- Script runs once during VM creation (not on reboot).

---

## 📄 Disclaimer

This module is provided as-is for demonstration purposes.  
**Striim Inc. is not responsible for infrastructure costs or operational consequences.**
You agree that Striim is not responsible for creating, deleting, or managing any GCP resources and is not liable for any associated costs in your Google account.
