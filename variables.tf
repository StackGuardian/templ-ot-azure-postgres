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

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "vnet_cidr" {
  description = "Address space of the VNet"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vnet_cidr))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "postgres_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "17"
}

variable "sku_name" {
  description = "SKU of the flexible server"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage in MB"
  type        = number
  default     = 32768
}

variable "administrator_login" {
  description = "Admin user name. The password is generated and stored in Key Vault."
  type        = string
  default     = "pgadmin"
}

variable "password_version" {
  description = "Increase to generate and set a new admin password"
  type        = number
  default     = 1
}

variable "backup_retention_days" {
  description = "Days to keep automated backups (7-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 7 and 35 days."
  }
}

variable "log_retention_days" {
  description = "Retention of the logs in Log Analytics"
  type        = number
  default     = 90
}
