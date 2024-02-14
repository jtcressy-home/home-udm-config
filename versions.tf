terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.25.0"
    }
    remote = {
      source  = "tenstad/remote"
      version = "0.1.1"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.6.0"
    }
    unifi = {
      source  = "paultyng/unifi"
      version = "0.41.0"
    }
    http-bin = {
      source  = "ndemeshchenko/http-bin"
      version = "1.0.1"
    }
  }
  required_version = ">=1.0"
}