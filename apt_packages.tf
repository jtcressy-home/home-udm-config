data "http" "unifi-tailscale-ip-rule-monitor-deb" {
  url = "https://github.com/jtcressy-home/unifi-tailscale-ip-rule-monitor/releases/download/0.1.2/unifi-tailscale-ip-rule-monitor_0.1.2_all.deb"
}

resource "ssh_resource" "apt_packages" {
  host      = "192.168.20.1"
  host_user = data.vault_generic_secret.unifiudm-ssh.data.username
  user      = data.vault_generic_secret.unifiudm-ssh.data.username
  password  = data.vault_generic_secret.unifiudm-ssh.data.password

  timeout = "15m"

  file {
    content     = data.http.unifi-tailscale-ip-rule-monitor-deb.response_body
    destination = "${local.persistent_storage_dir}/unifi-tailscale-ip-rule-monitor_0.1.2_all.deb"
    permissions = "0644"
  }

  commands = [
    "apt update -y",
    "apt install -yqq apt-transport-https wpasupplicant",
    # apt repo for tailscale
    "curl -fsSL https://pkgs.tailscale.com/stable/debian/stretch.gpg | apt-key add -",
    "curl -fsSL https://pkgs.tailscale.com/stable/debian/stretch.list | tee /etc/apt/sources.list.d/tailscale.list",
    # apt repo for docker
    "curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -",
    "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list",
    "apt update -y",
    "apt install -yqq tailscale docker-ce docker-ce-cli",
    "dpkg -i ${local.persistent_storage_dir}/unifi-tailscale-ip-rule-monitor_0.1.2_all.deb"
  ]
}