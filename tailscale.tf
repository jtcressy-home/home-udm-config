data "vault_generic_secret" "tailscale" {
  path = "generic/home-udm/tailscale"
}

locals {
  tailscale_args = join(" ", [
    "--authkey=$(cat ${local.systemd_data_dir}/tailscale-authkey)",
    "--accept-routes",
    "--advertise-exit-node",
    "--advertise-routes=${join(",", local.udm_network_cidrs)}",
    "--hostname=home-udm"
  ])
}

data "template_file" "tailscale-unit" {
  template = file("${path.module}/static/systemd-units/container-tailscaled@.service")
  vars = {
    persistent_storage_dir = local.persistent_storage_dir
    systemd_config_dir     = local.systemd_config_dir
    systemd_data_dir       = local.systemd_data_dir
    tailscale_args         = local.tailscale_args
  }
}

resource "ssh_resource" "tailscale" {
  host        = "192.168.20.1"
  host_user   = data.vault_generic_secret.unifiudm-ssh.data.username
  user        = data.vault_generic_secret.unifiudm-ssh.data.username
  private_key = data.remote_file.root-ssh.content

  file {
    content     = data.vault_generic_secret.tailscale.data.authkey
    destination = "${local.systemd_data_dir}/tailscale-authkey"
    permissions = "0400"
  }

  file {
    content     = data.template_file.tailscale-unit.rendered
    destination = "${local.systemd_unit_dir}/container-tailscaled@.service"
    permissions = "0600"
  }

  file {
    source      = "${path.module}/static/systemd-units/ip-rule-monitor.service"
    destination = "${local.systemd_unit_dir}/ip-rule-monitor.service"
    permissions = "0600"
  }

  file {
    source      = "${path.module}/static/scripts/ip-rule-monitor.sh"
    destination = "${local.persistent_storage_dir}/bin/ip-rule-monitor.sh"
    permissions = "0700"
  }

  timeout = "15m"

  commands = [
    "podman exec unifi-systemd systemctl daemon-reload",
    "podman exec unifi-systemd systemctl enable --now ip-rule-monitor.service",
    "podman exec unifi-systemd systemctl enable --now container-tailscaled@eth11.service",
  ]

  depends_on = [ssh_resource.unifi-systemd]
}