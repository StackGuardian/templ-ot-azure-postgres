resource "azurerm_postgresql_flexible_server" "this" {
  #checkov:skip=CKV_AZURE_136:Geo-redundant backups are out of scope for the demo (cost)
  #checkov:skip=CKV2_AZURE_57:VNet integration is used instead of a private endpoint
  name                              = "${var.name_prefix}-pg-${random_string.suffix.result}"
  location                          = azurerm_resource_group.this.location
  resource_group_name               = azurerm_resource_group.this.name
  version                           = var.advanced_settings.postgres_version
  sku_name                          = var.advanced_settings.sku_name
  storage_mb                        = var.advanced_settings.storage_mb
  delegated_subnet_id               = azurerm_subnet.db.id
  private_dns_zone_id               = azurerm_private_dns_zone.db.id
  public_network_access_enabled     = false
  administrator_login               = var.advanced_settings.administrator_login
  administrator_password_wo         = ephemeral.random_password.admin.result
  administrator_password_wo_version = var.advanced_settings.password_version
  backup_retention_days             = var.advanced_settings.backup_retention_days
  geo_redundant_backup_enabled      = false
  tags                              = local.tags

  authentication {
    password_auth_enabled = true
  }

  # Azure picks a zone if none is set.
  lifecycle {
    ignore_changes = [zone]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.db,
    azurerm_subnet_network_security_group_association.db,
  ]
}

resource "azurerm_postgresql_flexible_server_configuration" "settings" {
  for_each = {
    require_secure_transport     = "on"
    ssl_min_protocol_version     = "TLSv1.2"
    log_connections              = "on"
    log_disconnections           = "on"
    log_checkpoints              = "on"
    "connection_throttle.enable" = "on"
  }

  server_id = azurerm_postgresql_flexible_server.this.id
  name      = each.key
  value     = each.value
}

# Logs of the server and the Key Vault
resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name_prefix}-postgres-logs"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.advanced_settings.log_retention_days
  tags                = local.tags
}

resource "azurerm_monitor_diagnostic_setting" "postgres" {
  name                       = "logs"
  target_resource_id         = azurerm_postgresql_flexible_server.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "PostgreSQLLogs"
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "audit"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "AuditEvent"
  }
}
