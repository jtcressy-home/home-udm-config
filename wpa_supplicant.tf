data "vault_generic_secret" "att-bypass-tls" {
  path = "generic/home-udm/att-bypass-tls"
}

data "template_file" "wpa_supplicant-conf" {
  template = file("${path.module}/static/configs/wpa_supplicant/wpa_supplicant.conf")
  vars = {
    identity_mac = data.vault_generic_secret.att-bypass-tls.data.identity_mac
  }
}

resource "ssh_resource" "wpa_supplicant" {
  host      = "192.168.20.1"
  host_user = data.vault_generic_secret.unifiudm-ssh.data.username
  user      = data.vault_generic_secret.unifiudm-ssh.data.username
  password  = data.vault_generic_secret.unifiudm-ssh.data.password

  file {
    content = <<EOF
[Service]
ExecStart=
ExecStart=/sbin/wpa_supplicant -u -s -Dwired -ieth8 -c/etc/wpa_supplicant/conf/wpa_supplicant.conf

EOF
    destination = "/etc/systemd/system/wpa_supplicant.service.d/override.conf"
    permissions = "0644"
  }

  file {
    content     = data.template_file.wpa_supplicant-conf.rendered
    destination = "/etc/wpa_supplicant/conf/wpa_supplicant.conf"
    permissions = "0400"
  }

  file {
    content     = data.vault_generic_secret.att-bypass-tls.data.tls_ca
    destination = "/etc/wpa_supplicant/conf/tls_ca.pem"
    permissions = "0400"
  }

  file {
    content     = data.vault_generic_secret.att-bypass-tls.data.tls_cert
    destination = "/etc/wpa_supplicant/conf/tls_cert.pem"
    permissions = "0400"
  }

  file {
    content     = data.vault_generic_secret.att-bypass-tls.data.tls_key
    destination = "/etc/wpa_supplicant/conf/tls_key.pem"
    permissions = "0400"
  }

  timeout = "15m"

  commands = [
    "systemctl enable --now wpa_supplicant.service"
  ]

  depends_on = [ssh_resource.apt_packages]
}