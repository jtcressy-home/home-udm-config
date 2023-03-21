locals {
  persistent_storage_dir = "/persistent"
  external_storage_dir   = "/volume1"
  udm_network_cidrs = toset([
    "192.168.20.0/24",
    "192.168.22.0/24",
    "192.168.8.0/24",
    "192.168.66.0/24"
  ])
}