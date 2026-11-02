# Unit tests: plan only, providers are mocked. No cloud account, no cost.
# Run: tofu test -test-directory=tests/unit
# Test case catalog: tests/README.md

# Some arguments are validated as Azure resource IDs or UUIDs, so mocked values must look real.
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
      object_id = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-subnet"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/networkSecurityGroups/mock-nsg"
    }
  }

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/mock.private.postgres.database.azure.com"
    }
  }

  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.KeyVault/vaults/mock-kv"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.OperationalInsights/workspaces/mock-law"
    }
  }

  mock_resource "azurerm_postgresql_flexible_server" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.DBforPostgreSQL/flexibleServers/mock-pg"
    }
  }
}

# Mocked so the unit tests do not wait for the RBAC delay.
mock_provider "time" {
  mock_resource "time_offset" {
    defaults = {
      rfc3339 = "2027-11-02T00:00:00Z"
    }
  }
}

# U-01
run "defaults_are_valid" {
  command = plan

  assert {
    condition = (
      local.tags["Environment"] == "demo" &&
      local.tags["ManagedBy"] == "opentofu" &&
      local.tags["Project"] == var.name_prefix &&
      local.tags["Repository"] != ""
    )
    error_message = "Default tags are missing or wrong."
  }
}

# U-02
run "invalid_name_prefix_is_rejected" {
  command = plan

  variables {
    name_prefix = "Invalid_Prefix"
  }

  expect_failures = [var.name_prefix]
}

# U-03
run "custom_tags_are_merged" {
  command = plan

  variables {
    tags = {
      Owner = "tester"
    }
  }

  assert {
    condition     = local.tags["Owner"] == "tester" && local.tags["ManagedBy"] == "opentofu"
    error_message = "Custom tags are not merged with the default tags."
  }
}

# U-04
run "public_network_access_is_disabled" {
  command = apply

  assert {
    condition     = !azurerm_postgresql_flexible_server.this.public_network_access_enabled
    error_message = "Public network access must be disabled."
  }
}

# U-05
run "server_uses_delegated_subnet_and_private_dns" {
  command = apply

  assert {
    condition = (
      azurerm_postgresql_flexible_server.this.delegated_subnet_id == azurerm_subnet.db.id &&
      azurerm_postgresql_flexible_server.this.private_dns_zone_id == azurerm_private_dns_zone.db.id
    )
    error_message = "The server must use the delegated subnet and the private DNS zone."
  }

  assert {
    condition     = one(one(azurerm_subnet.db.delegation).service_delegation).name == "Microsoft.DBforPostgreSQL/flexibleServers"
    error_message = "The subnet must be delegated to PostgreSQL flexible servers."
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.db.virtual_network_id == azurerm_virtual_network.this.id
    error_message = "The private DNS zone must be linked to the VNet."
  }
}

# U-06
run "tls_is_enforced" {
  command = apply

  assert {
    condition = (
      azurerm_postgresql_flexible_server_configuration.settings["require_secure_transport"].value == "on" &&
      azurerm_postgresql_flexible_server_configuration.settings["ssl_min_protocol_version"].value == "TLSv1.2"
    )
    error_message = "TLS 1.2 or higher must be required."
  }
}

# U-07
run "password_is_write_only_and_in_key_vault" {
  command = apply

  assert {
    condition     = azurerm_postgresql_flexible_server.this.administrator_password == null
    error_message = "The admin password must be set only through the write-only argument."
  }

  assert {
    condition     = azurerm_key_vault_secret.admin_password.value == null && azurerm_key_vault_secret.admin_password.expiration_date != null
    error_message = "The secret must be written through the write-only argument and have an expiry date."
  }

  assert {
    condition     = azurerm_key_vault.this.rbac_authorization_enabled
    error_message = "Key Vault must use RBAC."
  }
}

# U-08
run "backups_are_enabled" {
  command = apply

  assert {
    condition     = azurerm_postgresql_flexible_server.this.backup_retention_days >= 7
    error_message = "Backups must be kept for at least 7 days."
  }
}

# U-09
run "short_backup_retention_is_rejected" {
  command = plan

  variables {
    backup_retention_days = 1
  }

  expect_failures = [var.backup_retention_days]
}

# U-10
run "logs_are_enabled" {
  command = apply

  assert {
    condition = (
      azurerm_monitor_diagnostic_setting.postgres.target_resource_id == azurerm_postgresql_flexible_server.this.id &&
      azurerm_monitor_diagnostic_setting.key_vault.target_resource_id == azurerm_key_vault.this.id
    )
    error_message = "Server logs and Key Vault audit logs must go to Log Analytics."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server_configuration.settings["log_connections"].value == "on"
    error_message = "Connections must be logged."
  }
}
