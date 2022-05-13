locals {
  persistent_storage_dir = "/mnt/data"
  external_storage_dir   = "/mnt/data_ext"
  on_boot_dir            = "${local.persistent_storage_dir}/on_boot.d"
  udm_network_cidrs = toset([
    "192.168.20.0/24",
    "192.168.22.0/24",
    "192.168.8.0/24",
    "192.168.66.0/24"
  ])
}