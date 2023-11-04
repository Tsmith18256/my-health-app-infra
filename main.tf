terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }

  backend "gcs" {
    bucket = "mha-terraform-remote-state"
    prefix = "terraform/state"
  }
}
locals {
  auth_file = file(var.credentials_file)
}
provider "google" {
  credentials = local.auth_file

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name = "mha-network"
}

resource "google_compute_firewall" "mha_firewall" {
  name    = "mha-firewall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = [ "0.0.0.0/0" ]
}

resource "google_compute_instance" "mha_server" {
  name         = "mha-server"
  machine_type = "e2-micro"

  allow_stopping_for_update = true

  service_account {
    scopes = [ "cloud-platform" ]
    email = var.service_account_name
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      # empty block configures public IP to be assigned
    }
  }

  metadata_startup_script = templatefile("${path.module}/${var.startup_script_file}", {
    auth_file            = base64encode(local.auth_file)
    service_account_name = var.service_account_name
  })
}
