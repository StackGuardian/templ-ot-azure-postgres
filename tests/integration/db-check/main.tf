# Helper for the integration test: reads the server and the secret names (not the values).
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "server_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "key_vault_id" {
  type = string
}

data "azurerm_postgresql_flexible_server" "this" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_secrets" "this" {
  key_vault_id = var.key_vault_id
}

output "public_network_access_enabled" {
  value = data.azurerm_postgresql_flexible_server.this.public_network_access_enabled
}

output "fqdn" {
  value = data.azurerm_postgresql_flexible_server.this.fqdn
}

output "secret_names" {
  value = data.azurerm_key_vault_secrets.this.names
}
