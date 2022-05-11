data "http" "podman-update" {
  url = "https://github.com/boostchicken-dev/udm-utilities/raw/master/podman-update/01-podman-update.sh"
}

data "http" "cni-plugins" {
  url = "https://raw.githubusercontent.com/boostchicken-dev/udm-utilities/HEAD/cni-plugins/05-install-cni-plugins.sh"
}

data "http" "cni-bridge" {
  url = "https://raw.githubusercontent.com/boostchicken-dev/udm-utilities/master/on-boot-script/examples/udm-networking/on_boot.d/06-cni-bridge.sh"
}