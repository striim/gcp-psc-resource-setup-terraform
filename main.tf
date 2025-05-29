locals {
  first_forwarding_port = length(var.ip_forwarding_targets) > 0 ? var.ip_forwarding_targets[0].port : 80
}

data "google_compute_network" "vpc" {
  name    = var.vpc_name
  project = var.project_id
}

data "google_compute_subnetwork" "subnet" {
  name    = var.subnet_name
  region  = var.region
  project = var.project_id
}

data "google_compute_subnetwork" "psc_nat_subnet" {
  name    = var.psc_nat_subnet_name
  region  = var.region
  project = var.project_id
}

data "template_file" "linux_startup_script" {
  template = file("${path.module}/forwarding-script.tpl")
  vars = {
    ip_forwarding_targets = jsonencode(var.ip_forwarding_targets)
  }
}

data "template_file" "windows_startup_script" {
  count    = var.vm_os_type == "windows" ? 1 : 0
  template = file("${path.module}/forwarding-script.ps1.tpl")
  vars = {
    ip_forwarding_targets = jsonencode(var.ip_forwarding_targets)
  }
}

resource "google_compute_firewall" "allow_ssh" {
  count   = var.vm_os_type == "linux" ? 1 : 0
  name    = "${var.base_name}-allow-ssh"
  network = data.google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.admin_public_ip]
}

resource "google_compute_firewall" "allow_rdp" {
  count   = var.vm_os_type == "windows" ? 1 : 0
  name    = "${var.base_name}-allow-rdp"
  network = data.google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = [var.admin_public_ip]
}

resource "google_compute_firewall" "allow_forwarding_ports" {
  name    = "${var.base_name}-allow-ports"
  network = data.google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = distinct([for target in var.ip_forwarding_targets : tostring(target.port)])
  }

  direction     = "INGRESS"
  source_ranges = [google_compute_forwarding_rule.internal_lb.ip_address]
  target_tags   = ["ip-forwarding"]
}

resource "google_compute_instance" "linux_forwarding_vm" {
  count          = var.vm_os_type == "linux" ? 1 : 0
  name           = "${var.base_name}-vm"
  machine_type   = var.vm_size
  zone           = var.zone
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.id
    dynamic "access_config" {
      for_each = var.enable_nat_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    startup-script = data.template_file.linux_startup_script.rendered
  }

  tags = ["ip-forwarding"]
}

resource "google_compute_instance" "windows_forwarding_vm" {
  count          = var.vm_os_type == "windows" ? 1 : 0
  name           = "${var.base_name}-vm"
  machine_type   = var.vm_size
  zone           = var.zone
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.id
    dynamic "access_config" {
      for_each = var.enable_nat_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    windows-startup-script-ps1 = data.template_file.windows_startup_script[0].rendered
  }

  tags = ["ip-forwarding", "rdp"]
}

resource "google_compute_instance_group" "vm_group" {
  name      = "${var.base_name}-group"
  zone      = var.zone
  instances = [
    var.vm_os_type == "linux" 
      ? google_compute_instance.linux_forwarding_vm[0].self_link 
      : google_compute_instance.windows_forwarding_vm[0].self_link
  ]

  dynamic "named_port" {
    for_each = var.ip_forwarding_targets
    content {
      name = "tcp-port"
      port = named_port.value.port
    }
  }
}

resource "google_compute_health_check" "tcp_health" {
  name = "${var.base_name}-tcp-health"

  tcp_health_check {
    port = local.first_forwarding_port
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

resource "google_compute_region_backend_service" "backend" {
  name                  = "${var.base_name}-backend"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  session_affinity      = "NONE"
  timeout_sec           = 30

  backend {
    group           = google_compute_instance_group.vm_group.self_link
    balancing_mode  = "CONNECTION"
    failover        = false
  }

  health_checks = [
    google_compute_health_check.tcp_health.self_link
  ]

  log_config {
    enable = false
  }

  network = data.google_compute_network.vpc.id
}

resource "google_compute_forwarding_rule" "internal_lb" {
  name                  = "${var.base_name}-ilb"
  load_balancing_scheme = "INTERNAL"
  ip_protocol           = "TCP"
  backend_service       = google_compute_region_backend_service.backend.self_link
  all_ports             = true
  subnetwork            = data.google_compute_subnetwork.subnet.id
  network               = data.google_compute_network.vpc.id
  region                = var.region
}

resource "google_compute_service_attachment" "psc_attachment" {
  name                  = "${var.base_name}-psc"
  region                = var.region
  target_service        = google_compute_forwarding_rule.internal_lb.self_link
  connection_preference = "ACCEPT_MANUAL"
  nat_subnets           = [data.google_compute_subnetwork.psc_nat_subnet.id]
  enable_proxy_protocol = false                                                         # ✅ Proxy protocol must be disabled for passthrough LB

  dynamic "consumer_accept_lists" {
    for_each = var.psc_consumer_projects
    content {
      project_id_or_num = consumer_accept_lists.value
      connection_limit  = 10
    }
  }
}
