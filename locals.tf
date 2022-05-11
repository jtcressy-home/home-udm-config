locals {
  persistent_storage_dir = "/mnt/data"
  external_storage_dir   = "/mnt/data_ext"
  on_boot_dir            = "${local.persistent_storage_dir}/on_boot.d"
}