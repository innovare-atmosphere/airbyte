terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./myKey"
  }
  provisioner "local-exec" {
    command = "echo '${tls_private_key.pk.public_key_openssh}' > ./myKey.pub"
  }
}

variable "do_token" {
  description = "This is the token of your DigitalOcean account where this software will be installed. You can get it by going to your DigitalOcean account and selecting API>Generate New Token."
}
variable "pvt_key" {
    default = "" #tls_private_key.pk.private_key_pem
}
variable "pub_key" {
    default = "" #tls_private_key.pk.public_key_openssh
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "terraform" {
  name = "terraform"
  public_key = var.pub_key != "" ? file(var.pub_key) : tls_private_key.pk.public_key_openssh
}
