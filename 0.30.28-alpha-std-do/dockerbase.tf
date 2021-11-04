variable "database_password" {
    default = ""
}

variable "domain" {
    default = ""
}

resource "random_password" "database_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}


resource "digitalocean_droplet" "www-mattermost" {
  #This has pre installed docker
  image = "docker-20-04"
  name = "www-mattermost"
  region = "nyc3"
  size = "s-1vcpu-1gb"
  ssh_keys = [
    digitalocean_ssh_key.terraform.id
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = var.pvt_key != "" ? file(var.pvt_key) : tls_private_key.pk.private_key_pem
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # install nginx and docker
      "sleep 5s",
      "apt update",
      "sleep 5s",
      "apt install -y nginx",
      "apt install -y python3-certbot-nginx",
      # create mattermost installation directory
      "mkdir /root/mattermost",
      "mkdir /root/mattermost/config",
      "chown -R 2000:2000 /root/mattermost/config",
      "mkdir /root/mattermost/data",
      "chown -R 2000:2000 /root/mattermost/data",
      "mkdir /root/mattermost/logs",
      "chown -R 2000:2000 /root/mattermost/logs",
      "mkdir /root/mattermost/plugins",
      "chown -R 2000:2000 /root/mattermost/plugins",
      "mkdir /root/mattermost/client_plugins",
      "chown -R 2000:2000 /root/mattermost/client_plugins",
    ]
  }

  provisioner "file" {
    content      = templatefile("docker-compose.yml.tpl", {
    })
    destination = "/root/mattermost/docker-compose.yml"
  }

  provisioner "file" {
    content      = templatefile(".env.tpl", {
      database_password = var.database_password != "" ? var.database_password : random_password.database_password.result
    })
    destination = "/root/mattermost/.env"
  }

  provisioner "file" {
    content      = templatefile("atmosphere-nginx.conf.tpl", {
      server_name = var.domain != "" ? var.domain : "0.0.0.0"
    })
    destination = "/etc/nginx/conf.d/atmosphere-nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # run compose
      "cd /root/mattermost",
      "docker-compose up -d",
      "rm /etc/nginx/sites-enabled/default",
      "systemctl restart nginx",
      "ufw allow http",
      "ufw allow https",
    ]
  }
}