output "resource_group_name" {
  description = "The name of the resource group in which resources are created"  
  value       = var.resource_group_name
}

output "administrator_login" {
  value       = var.administrator_login
  sensitive   = true
  description = "The postgresql instance login for the admin."
}

output "administrator_password" {
  value       = random_password.login_password.result
  sensitive   = true
  description = "The postgresql instance password for the admin."
}

output "primary_postgresql_server_name" {
  value       = azurerm_postgresql_server.primary.name
  description = "The Name of the postgresql instance."
}

output "primary_postgresql_server_id" {
  value       = azurerm_postgresql_server.primary.id
  description = "The ID of the postgresql instance."
}

output "primary_postgresql_server_fqdn" {
  description = "The fully qualified domain name of the primary Azure SQL Server" 
  value       = azurerm_postgresql_server.primary.fqdn
}

output "replica_postgresql_server_id" {
  description = "The replica Microsoft SQL Server ID"
  value       = element(concat(azurerm_postgresql_server.replica.*.id, [""]), 0)
}

output "replica_postgresql_server_fqdn" {
  description = "The fully qualified domain name of the replica Azure SQL Server" 
  value       = element(concat(azurerm_postgresql_server.replica.*.fqdn, [""]), 0)
}

# private link endpoint outputs
output "primary_postgresql_server_private_endpoint" {
  description = "id of the Primary postgresql server Private Endpoint"
  value       = element(concat(azurerm_private_endpoint.pep1.*.id, [""]), 0)
}

output "replica_postgresql_server_private_endpoint" {
  description = "id of the Primary postgresql server Private Endpoint"
  value       = element(concat(azurerm_private_endpoint.pep2.*.id, [""]), 0)
}

output "postgresql_server_private_dns_zone_domain" {
  description = "DNS zone name of postgresql server Private endpoints dns name records"
  value       = element(concat(azurerm_private_dns_zone.dns_zone.*.name, [""]), 0)
}


