resource "azurerm_key_vault" "this" {
  #checkov:skip=CKV_AZURE_109:OpenTofu writes the secret from outside the VNet, access is controlled by RBAC
  #checkov:skip=CKV_AZURE_189:OpenTofu writes the secret from outside the VNet, access is controlled by RBAC
  #checkov:skip=CKV2_AZURE_32:Private endpoint is out of scope for the demo
  #checkov:skip=CKV_AZURE_110:Purge protection would block re-deploying the demo for up to 90 days
  #checkov:skip=CKV_AZURE_42:Purge protection would block re-deploying the demo for up to 90 days
  name                       = "${substr(var.name_prefix, 0, 12)}-kv-${random_string.suffix.result}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = local.tags
}

# The identity running OpenTofu may write the admin password.
resource "azurerm_role_assignment" "deployer_secrets" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Role assignments need time to propagate.
resource "time_sleep" "rbac" {
  create_duration = "60s"

  depends_on = [azurerm_role_assignment.deployer_secrets]
}

resource "time_offset" "secret_expiry" {
  offset_days = 365
}

# Generated per apply and never stored in state. It is written only to
# write-only arguments when password_version changes.
ephemeral "random_password" "admin" {
  length           = 32
  special          = true
  override_special = "!#%*-_=+"
}

resource "azurerm_key_vault_secret" "admin_password" {
  name             = "postgres-admin-password"
  key_vault_id     = azurerm_key_vault.this.id
  value_wo         = ephemeral.random_password.admin.result
  value_wo_version = var.password_version
  content_type     = "password"
  expiration_date  = time_offset.secret_expiry.rfc3339
  tags             = local.tags

  depends_on = [time_sleep.rbac]
}
