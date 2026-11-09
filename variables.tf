variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.name_prefix))
    error_message = "Use 2-16 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = "germanywestcentral"
}

# Grouped so the StackGuardian form can show them in one "Advanced Settings" section.
variable "advanced_settings" {
  description = "Settings most deployments keep at their defaults"
  type = object({
    vnet_cidr             = optional(string, "10.0.0.0/16")     # Address space of the VNet
    postgres_version      = optional(string, "18")              # PostgreSQL major version
    sku_name              = optional(string, "B_Standard_B1ms") # SKU of the flexible server
    storage_mb            = optional(number, 32768)             # Storage in MB
    administrator_login   = optional(string, "pgadmin")         # Admin user name. The password is generated and stored in Key Vault.
    password_version      = optional(number, 1)                 # Increase to generate and set a new admin password
    backup_retention_days = optional(number, 7)                 # Days to keep automated backups (7-35)
    log_retention_days    = optional(number, 90)                # Retention of the logs in Log Analytics
    tags                  = optional(map(string), {})           # Additional tags for all resources
  })
  default  = {}
  nullable = false

  validation {
    condition     = can(cidrnetmask(var.advanced_settings.vnet_cidr))
    error_message = "vnet_cidr must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = var.advanced_settings.backup_retention_days >= 7 && var.advanced_settings.backup_retention_days <= 35
    error_message = "Backup retention must be between 7 and 35 days."
  }

  validation {
    condition     = var.advanced_settings.log_retention_days >= 30 && var.advanced_settings.log_retention_days <= 730
    error_message = "Log Analytics retention must be between 30 and 730 days."
  }
}
