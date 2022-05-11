data "vault_generic_secret" "att-bypass-tls" {
  path = "generic/att-bypass-tls"
}

resource "ssh_resource" "wpa_supplicant" {
  host        = "192.168.20.1"
  host_user   = data.vault_generic_secret.unifiudm-ssh.data.username
  user        = data.vault_generic_secret.unifiudm-ssh.data.username
  private_key = data.remote_file.root-ssh.content

  file {
    content     = <<EOF
#!/bin/sh
CONTAINER=wpa_supplicant-udmpro
IMAGE=docker.io/pbrah/wpa_supplicant-udmpro:v1.0
# All configs stored in /mnt/data/wpa_supplicant

if podman container exists $${CONTAINER} && [ "$(podman inspect $${CONTAINER} | jq -r '.[].ImageName')" != "$IMAGE" ]; then
  (podman pull $${IMAGE} && podman stop $${CONTAINER} && podman rm -f $${CONTAINER}) || (echo "Failed to update image, continuing anyway" && true)
fi
if podman container exists $${CONTAINER}; then
  podman start $${CONTAINER}
else
  podman run --privileged --network=host --name=$${CONTAINER} -v ${local.persistent_storage_dir}/wpa_supplicant/:/etc/wpa_supplicant/conf/ --log-driver=k8s-file --restart always -d -ti $${IMAGE} -Dwired -ieth8 -c/etc/wpa_supplicant/conf/wpa_supplicant.conf
fi
EOF
    destination = "${local.on_boot_dir}/00-wpa_supplicant.sh"
    permissions = "0700"
  }

  file {
    content     = <<EOF
eapol_version=1
ap_scan=0
fast_reauth=1
network={
        ca_cert="/etc/wpa_supplicant/conf/tls_ca.pem"
        client_cert="/etc/wpa_supplicant/conf/tls_cert.pem"
        eap=TLS
        eapol_flags=0
        identity="${data.vault_generic_secret.att-bypass-tls.data.identity_mac}" # Internet (ONT) interface MAC address must match this value
        key_mgmt=IEEE8021X
        phase1="allow_canned_success=1"
        private_key="/etc/wpa_supplicant/conf/tls_key.pem"
}
EOF
    destination = "${local.persistent_storage_dir}/wpa_supplicant/wpa_supplicant.conf"
    permissions = "0400"
  }

  file {
    content     = data.vault_generic_secret.att-bypass-tls.data.tls_ca
    destination = "${local.persistent_storage_dir}/wpa_supplicant/tls_ca.pem"
    permissions = "0400"
  }

  file {
    content     = data.vault_generic_secret.att-bypass-tls.data.tls_cert
    destination = "${local.persistent_storage_dir}/wpa_supplicant/tls_cert.pem"
    permissions = "0400"
  }

  file {
    content     = data.vault_generic_secret.att-bypass-tls.data.tls_key
    destination = "${local.persistent_storage_dir}/wpa_supplicant/tls_key.pem"
    permissions = "0400"
  }

  timeout = "15m"

  commands = [
    "${local.on_boot_dir}/00-wpa_supplicant.sh",
  ]
  depends_on = [ssh_resource.udm-boot-remote-install]
}