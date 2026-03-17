terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "= 3.3.0"
    }
    vault = {
      version = "= 4.7.0"
    }    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

  }
}

provider "docker" {}

provider "vault" {
  address = var.vaultAddress
  token   = var.vaultToken
}


locals {
  boundary = var.boundary.config
}

# Random username (lowercase, alphanumeric, starts with a letter)
resource "random_string" "rabbitmq_user" {
  length  = 10
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# Random password (strong, includes symbols)
resource "random_password" "rabbitmq_pass" {
  length           = 24
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}<>?."
}


resource "vault_generic_secret" "vault" {
  provider = vault
  for_each = { for a in local.boundary.docker : a.name => a 
  if a.name == "rabbitmq" }
  
  path = "secret/rabbitmq"  

  data_json = <<EOT
{
  "RABBITMQ_DEFAULT_USER": "${random_string.rabbitmq_user.result}",
  "RABBITMQ_DEFAULT_PASS": "${random_password.rabbitmq_pass.result}"
}
EOT
}

resource "docker_network" "docker_network" {
  for_each = { for a in local.boundary.docker : a.name => a }

  name = each.value.name
  ipam_config {
    subnet   = each.value.network.subnet
    ip_range = each.value.network.ipRange
    gateway  = each.value.network.gateway
  }
}

resource "docker_image" "docker_image" {
  for_each = { for a in local.boundary.docker : a.name => a }

  name = each.value.imageName
}

resource "docker_container" "docker_container" {
  for_each = { for a in local.boundary.docker : a.name => a }

  image = docker_image.docker_image[each.key].image_id
  name  = each.value.name

  
  env = [
    for k, v in merge(
      // Convert ["A=1","B=2"] -> { A = "1", B = "2" }
      {
        for item in tolist(try(each.value.env, [])) :
        // safer split: keep '=' inside the value part, if present
        split("=", item)[0] => join("=", slice(split("=", item), 1, length(split("=", item))))
      },
      // Use Vault map directly, not data_json; fallback to empty map
      try(vault_generic_secret.vault[each.key].data, {})
    ) : "${k}=${v}"
  ]

  dynamic "ports" {
    for_each = { for a in try(each.value.ports, []) : a.internal   => a }

    content{
      internal = ports.value.internal
      external = ports.value.external
    }
  }

  dynamic "networks_advanced" {
    for_each = { for a in try(each.value.networkAdvanced, []) : a.name => a }
    content {
      name = try(docker_network.docker_network[networks_advanced.value.name].name, networks_advanced.value.name) 
    }
  }

  dynamic "mounts" {
    for_each = { for a in try(each.value.mounts, []) : a.target => a }
  
    content {
      source = try(mounts.value.source, null)
      target = try(mounts.value.target, null)
      type   = try(mounts.value.type, null)
    }
  }
}