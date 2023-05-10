variable "database_password" {
    default = ""
}

variable "domain" {
    default = ""
}

variable "webmaster_email" {
    default = ""
}

resource "random_password" "database_password" {
  length           = 16
  special          = false
  override_special = "_%@"
}


resource "digitalocean_droplet" "www-airbyte" {
  #This has pre installed docker
  image = "docker-20-04"
  name = "www-airbyte"
  region = "nyc3"
  size = "s-2vcpu-4gb"
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
      # create airbyte installation directory
      "mkdir /root/airbyte",
    ]
  }

  provisioner "file" {
    source      = "docker-compose.yml.tpl"
    destination = "/root/airbyte/docker-compose.yml"
  }

  provisioner "file" {
    content      = templatefile(".env.tpl", {
      database_password = var.database_password != "" ? var.database_password : random_password.database_password.result
    })
    destination = "/root/airbyte/.env"
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
      "cd /root/airbyte",
      "docker compose up -d",
      "rm /etc/nginx/sites-enabled/default",
      "systemctl restart nginx",
      "ufw allow http",
      "ufw allow https",
      "%{if var.domain!= ""}certbot --nginx --non-interactive --agree-tos --domains ${var.domain} --redirect %{if var.webmaster_email!= ""} --email ${var.webmaster_email} %{ else } --register-unsafely-without-email %{ endif } %{ else }echo NOCERTBOT%{ endif }"
    ]
  }
}
