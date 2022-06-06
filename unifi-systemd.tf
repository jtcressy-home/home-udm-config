data "http" "unifi-systemd-deb" {
  url = "https://github.com/ntkme/unifi-systemd/releases/download/v1.0.0/unifi-systemd_1.0.0_all.deb"
}

resource "ssh_resource" "unifi-systemd" {
  host        = "192.168.20.1"
  host_user   = data.vault_generic_secret.unifiudm-ssh.data.username
  user        = data.vault_generic_secret.unifiudm-ssh.data.username
  private_key = data.remote_file.root-ssh.content

#  file {
#    content     = data.http.unifi-systemd-deb.response_body
#    destination = "${local.persistent_storage_dir}/unifi-os/unifi-systemd_1.0.0_all.deb"
#    permissions = "0600"
#  }

  file {
    content = <<EOF
[Unit]
Description=Unifi entrypoint@%i.service
Wants=network.target
After=network-online.target
ConditionPathIsDirectory=%f

[Service]
ExecStart=/usr/bin/podman run --rm --net host --volume /mnt/data/ssh/id_rsa:/root/.ssh/id_rsa:ro --volume /var/run/ssh_proxy_port:/etc/unifi-os/ssh_proxy_port:ro ghcr.io/ntkme/unifi-ssh-proxy:edge 'find -L "%f" -mindepth 1 -maxdepth 1 -type f -print0 | sort -z | xargs -0 -r -n 1 -- sh -c '\''if test -x "$0"; then echo "%n: running $0"; "$0"; else case "$0" in *.sh) echo "%n: sourcing $0"; . "$0";; *) echo "%n: ignoring $0";; esac; fi'\'
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    destination = "${local.persistent_storage_dir}/etc/systemd/system/unifi-entrypoint@.service"
  }

  timeout = "15m"

  commands = [
    "podman exec unifi-os curl -sLo /data/unifi-systemd_1.0.0_all.deb \"${data.http.unifi-systemd-deb.url}\"",
    "podman exec unifi-os dpkg -i /data/unifi-systemd_1.0.0_all.deb",
    "podman exec unifi-systemd systemctl enable unifi-entrypoint@mnt-data-on_boot.d.service"
  ]
}
