# Azure PostgreSQL Database (Flexible Server)

Creates an Azure Database for PostgreSQL Flexible Server that is reachable only from a private network. The admin password is generated during the run and stored in Azure Key Vault. It never appears in the state.

Use it when an application or a demo needs a secure PostgreSQL database on Azure.

## What gets created

- A resource group
- A virtual network with a subnet reserved for the database and a network security group
- A private DNS zone, so the server name resolves inside the network
- The PostgreSQL Flexible Server with private access only
- A Key Vault with the admin password
- A Log Analytics workspace with server logs and Key Vault audit logs

## Before you start

- A workflow with an Azure cloud connector for the target subscription
- The connector's identity needs rights to create resources **and** to assign roles (for example Owner, or Contributor plus User Access Administrator). It gets access to the Key Vault during the run
- A plan for how clients reach the database: they must run inside this network

## Form fields

| Field | What it does | Default |
|---|---|---|
| Name prefix | Prefix for all resource names. 2 to 16 lowercase letters, digits or hyphens, starting with a letter | `demo` |
| Location | Azure region | Germany West Central |

**Advanced Settings** (tick "Show advanced settings" to change them):

| Field | What it does | Default |
|---|---|---|
| VNet cidr | IP range of the new network | `10.0.0.0/16` |
| Postgres version | PostgreSQL major version. The list contains the versions in Azure standard support | `18` |
| Sku name | Size of the server: Burstable, General Purpose or Memory Optimized | Burstable B1ms |
| Storage mb | Storage in MB. At least 32768 (32 GiB) and divisible by 8 | `32768` |
| Administrator login | Name of the admin user | `pgadmin` |
| Password version | Raise this number and run again to create a new admin password | `1` |
| Backup retention days | How many days automated backups are kept, 7 to 35 | `7` |
| Log retention days | How long logs are kept | `90` |
| Tags | Extra tags added to all resources | none |

Not every server size is available in every region. If the run fails for that reason, pick another size or region.

## After the run

The workflow outputs show:

- `server_fqdn`: the server address. It resolves only inside the network
- `administrator_login`, `key_vault_id` and `admin_password_secret_name`: read the password from the Key Vault, for example in the Azure portal
- `resource_group_name` and `vnet_id`: deploy your clients into this network

Creating the server takes about 5 to 10 minutes.

## Security defaults

- No public access. Port 5432 is open only inside the network
- TLS required, minimum TLS 1.2
- The password is never written to the state. In Key Vault it expires after one year
- Automated backups are on
- Connections are logged, and server and Key Vault logs go to Log Analytics

## Cost and cleanup

The server and its storage are billed per hour, also when idle. Log ingestion is billed by usage. Destroy the resources from the workflow when the demo is over.

## Limits

- No access from outside the network
- Single server, no high availability standby
