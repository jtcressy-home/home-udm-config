
data "remote_file" "root-ssh" {
  provider = remote.home-udm
  path     = "/mnt/data/ssh/id_rsa"
}

resource "ssh_resource" "init" {
  host        = "192.168.20.1"
  host_user   = data.vault_generic_secret.unifiudm-ssh.data.username
  user        = data.vault_generic_secret.unifiudm-ssh.data.username
  private_key = data.remote_file.root-ssh.content

  file {
    content     = "echo Hello world"
    destination = "/tmp/hello.sh"
    permissions = "0700"
  }

  timeout = "15m"

  commands = [
    "/tmp/hello.sh"
  ]
}