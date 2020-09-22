# toggles on/off auditing and advanced threat protection policy for sql server
locals {
    if_threat_detection_policy_enabled = var.enable_threat_detection_policy ? [{}] : []                
}

# Configure the Azure Provider
provider "azurerm" {
  version = ">=2.2.0"
  features {}
}

# creates random password for postgresSQL admin account
resource "random_password" "login_password" {
  length      = 24
  special     = true
}

# Manages a PostgreSQL Server
resource "azurerm_postgresql_server" "primary" {
  name                = "primary-${var.names.product_name}-${var.names.environment}-${var.db_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  administrator_login          = var.administrator_login
  administrator_login_password = random_password.login_password.result

  sku_name   = var.sku_name
  version    = var.db_version
  storage_mb = var.storage_mb

  backup_retention_days             = var.backup_retention_days
  geo_redundant_backup_enabled      = var.geo_redundant_backup_enabled
  auto_grow_enabled                 = var.auto_grow_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"

  dynamic "threat_detection_policy" {
      for_each = local.if_threat_detection_policy_enabled
      content {
          storage_endpoint           = var.storage_endpoint
          storage_account_access_key = var.storage_account_access_key 
          retention_days             = var.log_retention_days
      }
  }
}

# Manages a PostgreSQL Server
resource "azurerm_postgresql_server" "replica" {
  count               = var.enable_replica ? 1 : 0
  name                = "replica-${var.names.product_name}-${var.names.environment}-${var.db_id}"
  location            = var.replica_server_location
  resource_group_name = var.resource_group_name

  administrator_login          = var.administrator_login
  administrator_login_password = random_password.login_password.result

  sku_name   = var.sku_name
  version    = var.db_version
  storage_mb = var.storage_mb

  backup_retention_days             = var.backup_retention_days
  geo_redundant_backup_enabled      = var.geo_redundant_backup_enabled
  auto_grow_enabled                 = var.auto_grow_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
  create_mode                       = var.create_mode
  creation_source_server_id         = azurerm_postgresql_server.primary.id

  dynamic "threat_detection_policy" {
      for_each = local.if_threat_detection_policy_enabled
      content {
          storage_endpoint           = var.storage_endpoint
          storage_account_access_key = var.storage_account_access_key 
          retention_days             = var.log_retention_days
      }
  }
}

# Manages a PostgreSQL Database within a PostgreSQL Server
resource "azurerm_postgresql_database" "db" {
  count               = var.enable_db ? 1 : 0
  name                = "db-${var.names.product_name}-${var.names.environment}-${var.db_id}"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.primary.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# Sets a PostgreSQL Configuration value on a PostgreSQL Server.
resource "azurerm_postgresql_configuration" "config" {
  for_each            = local.postgresql_config

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.primary.name
  value               = each.value
}

# Sets a PostgreSQL Configuration value on a PostgreSQL Server.
resource "azurerm_postgresql_configuration" "config_replica" {
  for_each            = local.postgresql_config

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.replica.0.name
  value               = each.value
}

data "azurerm_client_config" "current" {}

# PostgreSQL Azure AD Admin - Default is "false"
resource "azurerm_postgresql_active_directory_administrator" "aduser1" {
  count               = var.enable_postgresql_ad_admin ? 1 : 0
  server_name         = azurerm_postgresql_server.primary.name
  resource_group_name = var.resource_group_name
  login               = var.ad_admin_login_name 
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
}

resource "azurerm_postgresql_active_directory_administrator" "aduser2" {
  count               = var.enable_replica && var.enable_postgresql_ad_admin ? 1 : 0
  server_name         = azurerm_postgresql_server.replica.0.name
  resource_group_name = var.resource_group_name
  login               = var.ad_admin_login_name_replica
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
}

# PostgreSQL Firewall Rule - Default is "false"
resource "azurerm_postgresql_firewall_rule" "fw01" {
  count               = var.enable_firewall_rules && length(var.firewall_rules) > 0 ? length(var.firewall_rules) : 0
  name                = element(var.firewall_rules, count.index).name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.primary.name
  start_ip_address    = element(var.firewall_rules, count.index).start_ip_address
  end_ip_address      = element(var.firewall_rules, count.index).end_ip_address
}

resource "azurerm_postgresql_firewall_rule" "fw02" {
  count               = var.enable_replica && var.enable_firewall_rules && length(var.firewall_rules) > 0 ? length(var.firewall_rules) : 0
  name                = element(var.firewall_rules, count.index).name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.replica.0.name
  start_ip_address    = element(var.firewall_rules, count.index).start_ip_address
  end_ip_address      = element(var.firewall_rules, count.index).end_ip_address
}

# PostgreSQL Virtual Network Rule - Default is "false"
resource "azurerm_postgresql_virtual_network_rule" "vn_rule01" {
  count = var.enable_vnet_rule && length(var.allowed_subnets) > 0 ? length(var.allowed_subnets) : 0

  name = format(
    "%s-%s",
    element(split("/", var.allowed_subnets[count.index]), 8), # VNet name
    element(split("/", var.allowed_subnets[count.index]), 10) # Subnet name
  )
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.primary.name
  subnet_id           = var.allowed_subnets[count.index]
}

# PostgreSQL Virtual Network Rule - Default is "false"
resource "azurerm_postgresql_virtual_network_rule" "vn_rule02" {
 count = var.enable_replica && var.enable_vnet_rule && length(var.allowed_subnets) > 0 ? length(var.allowed_subnets) : 0

  name = format(
    "%s-%s",
    element(split("/", var.allowed_subnets[count.index]), 8), # VNet name
    element(split("/", var.allowed_subnets[count.index]), 10) # Subnet name
  )
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.replica.0.name
  subnet_id           = var.allowed_subnets[count.index]
}

# Private Link Endpoint for postgresSQL Server - Existing vnet
data "azurerm_virtual_network" "vnet01" {
  name                = var.virtual_network_name
  resource_group_name = var.vnet_resource_group_name
}

# Private Link Endpoint for postgresSQL Server - Default is "false" 
resource "azurerm_subnet" "snet_ep" {
    count                   = var.enable_private_endpoint ? 1 : 0
    name                    = var.subnet_name
    resource_group_name     = var.resource_group_name
    virtual_network_name    = var.virtual_network_name
    address_prefixes        = var.allowed_cidrs
    enforce_private_link_endpoint_network_policies = true
}

# Enables you to manage Private DNS zone Virtual Network Links. 
# These Links enable DNS resolution and registration inside Azure Virtual Networks using Azure Private DNS.
resource "azurerm_private_dns_zone" "dns_zone" {
  count               = var.enable_private_endpoint ? 1 : 0    
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = merge({"Name" = format("%s", "postgresSQL-Private-DNS-Zone")}, var.tags,)
}

# Enables you to manage Private DNS zone Virtual Network Links. 
# These Links enable DNS resolution and registration inside Azure Virtual Networks using Azure Private DNS.
resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_vnet" {
  count                 = var.enable_private_endpoint ? 1 : 0    
  name                  = "dns-${var.names.product_name}-${var.names.environment}-${var.db_id}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.0.name
  virtual_network_id    = data.azurerm_virtual_network.vnet01.id
  tags                  = merge({"Name" = format("%s", "vnet-private-zone-link")}, var.tags,)
}

# Azure Private Endpoint is a network interface that connects you privately and securely to a service powered by Azure Private Link. 
# Private Endpoint uses a private IP address from your VNet, effectively bringing the service into your VNet. The service could be an Azure service such as Azure Storage, postgresSQL, etc. or your own Private Link Service.
resource "azurerm_private_endpoint" "pep1" {
  count               = var.enable_private_endpoint ? 1 : 0    
  name                = "endpoint-${var.names.product_name}-${var.names.environment}-${var.db_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.snet_ep.0.id
  tags                = merge({"Name" = format("%s", "postgresSQLdb-private-endpoint")}, var.tags,)

  private_service_connection {
    name                           = "prv-serv-conn-${var.names.product_name}-${var.names.environment}-${var.db_id}"
    private_connection_resource_id = azurerm_postgresql_server.primary.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_postgresql_server.primary.name
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.0.id]
  }
}

# Azure Private Endpoint is a network interface that connects you privately and securely to a service powered by Azure Private Link. 
# Private Endpoint uses a private IP address from your VNet, effectively bringing the service into your VNet. The service could be an Azure service such as Azure Storage, SQL, etc. or your own Private Link Service.
resource "azurerm_private_endpoint" "pep2" {
  count               = var.enable_replica && var.enable_private_endpoint ? 1 : 0  
  name                = "endpoint-replica${var.names.product_name}-${var.names.environment}-${var.db_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.snet_ep.0.id
  tags                = merge({"Name" = format("%s", "db-private-endpoint")}, var.tags,)

  private_service_connection {
    name                           = "prv-serv-conn-${var.names.product_name}-${var.names.environment}-${var.db_id}"
    private_connection_resource_id = azurerm_postgresql_server.replica.0.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_postgresql_server.replica.0.name
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.0.id]
  }
}

