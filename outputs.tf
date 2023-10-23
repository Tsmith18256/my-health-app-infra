output "ip" {
  value = google_compute_instance.mha_server.network_interface.0.network_ip
}
