data "vault_generic_secret" "tailscale" {
  path = "generic/home-udm/tailscale"
}

locals {
  tailscale_args = join(" ", [
    "--authkey=${data.vault_generic_secret.tailscale.data.authkey}",
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
    content     = <<EOF
#!/bin/sh
CONTAINER=tailscaled
IMAGE=ghcr.io/tailscale/tailscale:v1.24.2
# Starts a Tailscale container that is deleted after it is stopped.
# All configs stored in /mnt/data/tailscale

if podman container exists $${CONTAINER} && [ "$(podman inspect $${CONTAINER} | jq -r '.[].ImageName')" != "$IMAGE" ]; then
  (podman pull $${IMAGE} && podman stop $${CONTAINER} && podman rm -f $${CONTAINER}) || (echo "Failed to pull image" && true)
fi
if podman container exists $${CONTAINER}; then
  podman start $${CONTAINER}
else
  podman run --rm --device=/dev/net/tun --net=host --cap-add=NET_ADMIN --cap-add=SYS_ADMIN --cap-add=CAP_SYS_RAWIO -v /mnt/data/tailscale:/var/lib/tailscale -v /mnt/data/tailscale/resolv.conf:/etc/resolv.conf --name=$${CONTAINER} -d --entrypoint /bin/sh $${IMAGE} -c "tailscaled --tun eth52"
fi

kill -9 $(cat ${local.persistent_storage_dir}/tailscale/monitor.pid)
${local.persistent_storage_dir}/tailscale/ip-rule-monitor.sh &
monitor_pid=$!
echo $monitor_pid > ${local.persistent_storage_dir}/tailscale/monitor.pid

EOF
    destination = "${local.on_boot_dir}/11-tailscale.sh"
    permissions = "0700"
  }

  file {
    content     = <<EOF
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
    destination = "${local.persistent_storage_dir}/tailscale/ip-rule-monitor.sh"
    permissions = "0700"
  }

  timeout = "15m"

  commands = [
    "${local.on_boot_dir}/11-tailscale.sh",
    "sleep 10 && podman exec tailscaled tailscale status && podman exec tailscaled tailscale up ${local.tailscale_args}",
  ]
  depends_on = [ssh_resource.udm-boot-remote-install, ssh_resource.on-boot-scripts]
}