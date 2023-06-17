data "vault_generic_secret" "tailscale" {
  path = "generic/home-udm/tailscale"
}

locals {
  tailscale_args = join(" ", [
    "--accept-routes",
    "--advertise-exit-node",
    "--advertise-routes=${join(",", local.udm_network_cidrs)}",
    "--ssh",
  ])
}

resource "ssh_resource" "tailscale" {
  host     = "192.168.20.1"
  user     = data.vault_generic_secret.unifiudm-ssh.data.username
  password = data.vault_generic_secret.unifiudm-ssh.data.password

  timeout = "15m"

  commands = [
    "systemctl daemon-reload",
    "systemctl enable --now tailscale-ip-rule-monitor.service",
    "systemctl enable --now tailscaled.service",
    "tailscale set ${local.tailscale_args}",
  ]

  depends_on = [ssh_resource.apt_packages]
}