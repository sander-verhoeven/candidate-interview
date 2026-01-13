terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "= 3.3.0"
    }
    vault = {
      version = "= 4.7.0"
    }
  }
}

provider "docker" {}

provider "vault" {
  address = "http://localhost:8200"
  token   = "dev"
}

resource "docker_network" "rabbitmq" {
  name = "rabbitmq"
  ipam_config {
    subnet = "172.18.1.32/28"
    ip_range = "172.18.1.32/28"
    gateway = "172.18.1.33"
  }
}

resource "docker_image" "rabbitmq" {
  name = "rabbitmq:4.1.2-management-alpine"
}

resource "docker_container" "rabbitmq" {
  image = docker_image.rabbitmq.image_id
  name = "rabbitmq"

  networks_advanced {
    name = "rabbitmq"
  }

  env = [
    "RABBITMQ_DEFAULT_USER=dev",
    "RABBITMQ_DEFAULT_PASS=dev"
  ]

  depends_on = [ 
    docker_image.rabbitmq,
    docker_network.rabbitmq
  ]
}

resource "docker_image" "nginx" {
  name = "nginx:1.27.5"
}

resource "docker_network" "nginx" {
  name = "nginx"
  ipam_config {
    subnet = "172.18.1.0/28"
    ip_range = "172.18.1.0/28"
    gateway = "172.18.1.1"
  }
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name = "nginx"

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = "nginx"
  }

  networks_advanced {
    name = "rabbitmq"
  }

  networks_advanced {
    name = "vault"
  }

  mounts {
    source = "/vagrant/source/nginx/conf.d/default.conf"
    target = "/etc/nginx/conf.d/default.conf"
    type = "bind"
  }

  depends_on = [ 
    docker_image.nginx,
    docker_network.nginx
  ]
}

resource "vault_generic_secret" "vault" {
  path     = "secret/rabbitmq"

  data_json = <<EOT
{
  "rabbitmq_user": "dev",
  "rabbitmq_pass": "dev"
}
EOT

  depends_on = [ 
    docker_image.nginx,
    docker_network.nginx
  ]
}

