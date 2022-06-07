data "vault_generic_secret" "tailscale" {
  path = "generic/home-udm/tailscale"
}

locals {
  tailscale_args = join(" ", [
    "--authkey=file:${local.systemd_config_dir}/tailscale-authkey",
    "--accept-routes",
    "--advertise-exit-node",
    "--advertise-routes=${join(",", local.udm_network_cidrs)}",
    "--hostname=home-udm"
  ])
}

resource "ssh_resource" "tailscale" {
  host        = "192.168.20.1"
  host_user   = data.vault_generic_secret.unifiudm-ssh.data.username
  user        = data.vault_generic_secret.unifiudm-ssh.data.username
  private_key = data.remote_file.root-ssh.content

  file {
    content = data.vault_generic_secret.tailscale.data.authkey
    destination = "${local.systemd_config_dir}/tailscale-authkey"
    permissions = "0400"
  }

  file {
    content     = <<EOF
[Unit]
Description=Podman container-tailscaled@%i.service
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --sdnotify=conmon --cgroups=no-conmon --rm -d --replace --name tailscaled-%i --label io.containers.autoupdate=image --cap-add NET_ADMIN --cap-add SYS_ADMIN --cap-add CAP_SYS_RAWIO --network host --volume ${local.systemd_data_dir}/tailscale/%i:/var/lib/tailscale --volume ${local.systemd_data_dir}/tailscale/%i/resolv.conf:/etc/resolv.conf --entrypoint /bin/sh ghcr.io/tailscale/tailscale:latest -c "tailscaled --tun %i"
ExecStartPost=/usr/bin/podman exec --cidfile=%t/%n.ctr-id tailscale up ${local.tailscale_args}
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=multi-user.target
EOF
    destination = "${local.systemd_unit_dir}/container-tailscaled@.service"
    permissions = "0600"
  }

  file {
    content = <<EOF
[Unit]
Description=Monitors ip rules for better default route discovery by tailscale
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/podman run --rm --net host --volume /mnt/data/ssh/id_rsa:/root/.ssh/id_rsa:ro --volume /var/run/ssh_proxy_port:/etc/unifi-os/ssh_proxy_port:ro ghcr.io/ntkme/unifi-ssh-proxy:edge '/bin/sh "${local.persistent_storage_dir}/bin/ip-rule-monitor.sh"'
TimeoutStartSec=0
Restart=always
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF
    destination = "${local.systemd_unit_dir}/ip-rule-monitor.service"
    permissions = "0600"
  }

  file {
    content     = <<EOF
#!/bin/sh
RULE_PRIORITY="5225"

function getDefaultTable() {
        /sbin/ip rule list priority 32766 | cut -d " " -f 4
}

function updateTailscaleRule() {
        /sbin/ip rule del priority $RULE_PRIORITY
        /sbin/ip rule add priority $RULE_PRIORITY from all fwmark 0x80000 lookup $1
}

echo Routing table with default route is $(getDefaultTable)
updateTailscaleRule $(getDefaultTable)

tail -Fn 0  /var/log/messages | while read line; do
        table=`echo $line | grep -e "ubios-udapi-server: wanFailover"`
        if [[ "$table" != ""  ]]
        then
                echo Detected WAN failover: Routing table with default route is $(getDefaultTable) now, adjusting rule >> /var/log/messages
                updateTailscaleRule $(getDefaultTable)
        fi
done
EOF
    destination = "${local.persistent_storage_dir}/bin/ip-rule-monitor.sh"
    permissions = "0700"
  }

  timeout = "15m"

  commands = [
    "podman exec unifi-systemd systemctl daemon-reload",
    "podman exec unifi-systemd systemctl enable --now ip-rule-monitor.service",
    "podman exec unifi-systemd systemctl enable --now container-tailscaled@eth11.service"
  ]

  depends_on = [ssh_resource.unifi-systemd]
}