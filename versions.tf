terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.5.0"
    }
    remote = {
      source  = "tenstad/remote"
      version = "0.1.1"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "1.2.0"
    }
    unifi = {
      source  = "paultyng/unifi"
      version = "0.34.0"
    }
  }
  required_version = ">=1.0"
}