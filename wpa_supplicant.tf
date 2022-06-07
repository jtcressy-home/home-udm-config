data "vault_generic_secret" "att-bypass-tls" {
  path = "generic/home-udm/att-bypass-tls"
}

data "template_file" "wpa_supplicant-unit" {
  template = file("${path.module}/static/systemd-units/container-wpa_supplicant@.service")
  vars = {
    persistent_storage_dir = local.persistent_storage_dir
    systemd_config_dir     = local.systemd_config_dir
    systemd_data_dir       = local.systemd_data_dir
  }
}

data "template_file" "wpa_supplicant-conf" {
  template = file("${path.module}/static/configs/wpa_supplicant/wpa_supplicant.conf")
  vars = {
    identity_mac = data.vault_generic_secret.att-bypass-tls.data.identity_mac
  }
}

resource "ssh_resource" "wpa_supplicant-pre" {
  host        = "192.168.20.1"
  host_user   = data.vault_generic_secret.unifiudm-ssh.data.username
  user        = data.vault_generic_secret.unifiudm-ssh.data.username
  private_key = data.remote_file.root-ssh.content

  timeout = "15m"

  commands = [
    "mkdir -p ${local.systemd_config_dir}/wpa_supplicant/",
  ]
}

resource "ssh_resource" "wpa_supplicant" {
  host        = "192.168.20.1"
  host_user   = data.vault_generic_secret.unifiudm-ssh.data.username
  user        = data.vault_generic_secret.unifiudm-ssh.data.username
  private_key = data.remote_file.root-ssh.content

  file {
    content     = data.template_file.wpa_supplicant-unit.rendered
    destination = "${local.systemd_unit_dir}/container-wpa_supplicant@.service"
    permissions = "0600"
  }

  file {
    content     = data.template_file.wpa_supplicant-conf.rendered
    destination = "${local.systemd_config_dir}/wpa_supplicant/wpa_supplicant.conf"
    permissions = "0400"
  }

  file {
    content     = data.vault_generic_secret.att-bypass-tls.data.tls_ca
    destination = "${local.systemd_config_dir}/wpa_supplicant/tls_ca.pem"
    permissions = "0400"
  }

  file {
    content     = data.vault_generic_secret.att-bypass-tls.data.tls_cert
    destination = "${local.systemd_config_dir}/wpa_supplicant/tls_cert.pem"
    permissions = "0400"
  }

  file {
    content     = data.vault_generic_secret.att-bypass-tls.data.tls_key
    destination = "${local.systemd_config_dir}/wpa_supplicant/tls_key.pem"
    permissions = "0400"
  }

  timeout = "15m"

  commands = [
    "podman exec unifi-systemd systemctl daemon-reload",
    "podman exec unifi-systemd systemctl enable --now container-wpa_supplicant@eth8.service"
  ]

  depends_on = [ssh_resource.unifi-systemd, ssh_resource.wpa_supplicant-pre]
}