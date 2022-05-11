data "http" "remote_install-sh" {
  url = "https://raw.githubusercontent.com/boostchicken-dev/udm-utilities/HEAD/on-boot-script/remote_install.sh"
}

resource "ssh_resource" "udm-boot-remote-install" {
  host        = "192.168.20.1"
  host_user   = data.vault_generic_secret.unifiudm-ssh.data.username
  user        = data.vault_generic_secret.unifiudm-ssh.data.username
  private_key = data.remote_file.root-ssh.content

  file {
    content     = data.http.remote_install-sh.body
    destination = "${local.persistent_storage_dir}/udm-boot-install.sh"
    permissions = "0700"
  }

  timeout = "15m"

  commands = [
    "${local.persistent_storage_dir}/udm-boot-install.sh",
    "podman exec unifi-os systemctl daemon-reload",
    "podman exec unifi-os systemctl enable udm-boot"
  ]
}

resource "ssh_resource" "on-boot-scripts" {
  host        = "192.168.20.1"
  host_user   = data.vault_generic_secret.unifiudm-ssh.data.username
  user        = data.vault_generic_secret.unifiudm-ssh.data.username
  private_key = data.remote_file.root-ssh.content

  # file {
  #   content     = data.http.podman-update.body
  #   destination = "${local.on_boot_dir}/01-podman-update.sh"
  #   permissions = "0700"
  # }

  file {
    content     = data.http.cni-plugins.body
    destination = "${local.on_boot_dir}/05-install-cni-plugins.sh"
    permissions = "0700"
  }

  file {
    content     = data.http.cni-bridge.body
    destination = "${local.on_boot_dir}/06-cni-bridge.sh"
    permissions = "0700"
  }

  timeout = "15m"

  commands = [
    # "${local.on_boot_dir}/01-podman-update.sh",
    "${local.on_boot_dir}/05-install-cni-plugins.sh",
    "${local.on_boot_dir}/06-cni-bridge.sh"
  ]
  depends_on = [ssh_resource.udm-boot-remote-install]
}