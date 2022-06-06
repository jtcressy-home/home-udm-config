provider "vault" {}

data "vault_generic_secret" "unifiudm-ssh" {
  path = "generic/home-udm/ssh"
}

provider "remote" {
  alias        = "home-udm"
  max_sessions = 2

  conn {
    host     = "192.168.20.1"
    user     = data.vault_generic_secret.unifiudm-ssh.data.username
    password = data.vault_generic_secret.unifiudm-ssh.data.password
    sudo     = true
  }
}

data "remote_file" "root-ssh" {
  provider = remote.home-udm
  path     = "/mnt/data/ssh/id_rsa"
}

data "vault_generic_secret" "unifiudm-api" {
  path = "generic/home-udm/unifi"
}

provider "unifi" {
  username       = data.vault_generic_secret.unifiudm-api.data.username
  password       = data.vault_generic_secret.unifiudm-api.data.password
  api_url        = "https://192.168.20.1/proxy"
  allow_insecure = true
}