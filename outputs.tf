output "server_fqdn" {
  description = "FQDN of the server. Resolves only inside the VNet."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "server_name" {
  description = "Name of the server"
  value       = azurerm_postgresql_flexible_server.this.name
}

output "administrator_login" {
  description = "Admin user name"
  value       = azurerm_postgresql_flexible_server.this.administrator_login
}

output "key_vault_id" {
  description = "ID of the Key Vault with the admin password"
  value       = azurerm_key_vault.this.id
}

output "admin_password_secret_name" {
  description = "Name of the Key Vault secret with the admin password"
  value       = azurerm_key_vault_secret.admin_password.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "ID of the VNet, for clients that need to reach the server"
  value       = azurerm_virtual_network.this.id
}
