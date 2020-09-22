##
# Required parameters
##

variable "sku_name" {
    type        = string
    description = "Specifies the SKU Name for this PostgreSQL Server. The name of the SKU, follows the tier + family + cores pattern (e.g. B_Gen4_1, GP_Gen5_8)."
    default     = "GP_Gen5_2"
}

variable "storage_mb" {
    type        = number
    description = "Max storage allowed for a server. Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB) for General Purpose/Memory Optimized SKUs."
    default     = "10240"
}

variable "db_version" {
    type        = string
    description = "Specifies the version of PostgreSQL to use. Valid values are 9.5, 9.6, 10, 10.0, and 11."
    default     = "9.6"
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "replica_server_location" {
  description = "Specifies the supported Azure location to create secondary sql server resource"
  type        = string
  default     = "westus"
}

variable "resource_group_name" {
  description = "name of the resource group to create the resource"
  type        = string
}

variable "vnet_resource_group_name" {
  description = "name of the resource group that contains the virtual network"
  type        = string
}

variable "names" {
  description = "names to be applied to resources"
  type        = map(string)
}

variable "tags" {
  description = "tags to be applied to resources"
  type        = map(string)
}

variable "db_id" {
  description = "identifier appended to db name (productname-environment-postgresql<db_id>)"
  type        = string
  default     = "1337"
}

variable "enable_db" {
  description = "toggles on/off postgresql Database within a postgresql Server"
  type        = bool
  default     = "false"
}

variable "postgresql_version" {
  type        = string
  description = "postgresql version"
  default     = "8.0"
}

variable "storage_endpoint" {
    description = "This blob storage will hold all Threat Detection audit logs. Required if state is Enabled."
    type        = string
}

variable "storage_account_access_key" {
    description = "Specifies the identifier key of the Threat Detection audit storage account. Required if state is Enabled."
    type        = string
}

variable "log_retention_days" {
    description = "Specifies the number of days to keep in the Threat Detection audit logs"
    default     = "7"
}

variable "auto_grow_enabled" {
    description = "Enable/Disable auto-growing of the storage. Storage auto-grow prevents your server from running out of storage and becoming read-only. If storage auto grow is enabled, the storage automatically grows without impacting the workload. The default value if not explicitly specified is true."
    default     = "false"
}

variable "enable_private_endpoint" {
    description = "Enable/Disable private link endpoint. Azure Private Endpoint is a network interface that connects you privately and securely to a service powered by Azure Private Link."
    default     = "false"
}

variable "enable_firewall_rules" {
    description = "Manage an Azure SQL Firewall Rule"
    type        = bool
    default     = false
}

variable "enable_vnet_rule" {
    description = "Creates a virtual network rule to allows access to an Azure postgresql server."
    type        = bool
    default     = false
}

variable "firewall_rules" {
  description = "Range of IP addresses to allow firewall connections."
  type = list(object({
    name             = string
    start_ip_address = string
    end_ip_address   = string
  }))
  default = []
}

variable "allowed_cidrs" {
  type        = list(string)
  description = "List of authorized cidrs"
}

variable "allowed_subnets" {
  type        = list(string)
  description = "List of authorized subnet ids"
  default     = []
}

variable "enable_postgresql_ad_admin" {
  description = "Set a user or group as the AD administrator for an postgresql server in Azure"
  type        = bool
  default     = false
}

variable "ad_admin_login_name" {
  description = "The login name of the principal to set as the server administrator."
  type        = string
}

variable "ad_admin_login_name_replica" {
  description = "The login name of the principal to set as the server administrator for the replica."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of existing virtual network."
  type        = string
}

variable "subnet_name" {
  description = "Name of new subnet virtual network."
  type        = string
}

variable "enable_replica" {
  description = "toggle on/off creation of replica server."
  type        = bool
}

variable "create_mode" {
    type        = string
    description = "Can be used to restore or replicate existing servers. Possible values are Default, Replica, GeoRestore, and PointInTimeRestore. Defaults to Default"
}

variable "creation_source_server_id" {
    type        = string
    description = "the source server ID to use. use this only when creating a read replica server"
}

variable "enable_threat_detection_policy" {
    description = "Threat detection policy configuration, known in the API as Server Security Alerts Policy."
    type        = bool
    default     = false 
}

##
# Optional Parameters
##

variable "administrator_login" {
    type        = string
    description = "Database administrator login name"
    default     = "az_dbadmin"
}

variable "backup_retention_days" {
    type        = number
    description = "Backup retention days for the server, supported values are between 7 and 35 days."
    default     = "7"
}

variable "geo_redundant_backup_enabled" {
    type        = string
    description = "Turn Geo-redundant server backups on/off. This allows you to choose between locally redundant or geo-redundant backup storage in the General Purpose and Memory Optimized tiers. When the backups are stored in geo-redundant backup storage, they are not only stored within the region in which your server is hosted, but are also replicated to a paired data center. This provides better protection and ability to restore your server in a different region in the event of a disaster. This is not supported for the Basic tier."
    default     = "true"
}

variable "infrastructure_encryption_enabled" {
    type        = string
    description = "Whether or not infrastructure is encrypted for this server. Defaults to false. Changing this forces a new resource to be created."
    default     = "true"
}

variable "public_network_access_enabled" {
    type        = string
    description = "Whether or not public network access is allowed for this server."
    default     = "false"
}

variable "threat_detection_policy" {
    type        = string
    description = "Threat detection policy configuration, known in the API as Server Security Alerts Policy. The threat_detection_policy block supports fields documented below."
    default     = "false"
}

##
# Required PostgreSQL Server Parameters
##

variable "track_utility" {
  type        = string
  description = "Selects whether utility commands are tracked by pg_qs."
  default     = "ON"
}

variable "retention_period_in_days" {
  type        = string
  description = "Sets the retention period window in days for pg_qs - after this time data will be deleted."
  default     = "7"
}

variable "replace_parameter_placeholders" {
  type        = string
  description = "Selects whether parameter placeholders are replaced in parameterized queries."
  default     = "OFF"
}

variable "query_capture_mode" {
  type        = string
  description = "Selects whether parameter placeholders are replaced in parameterized queries."
  default     = "TOP"
}
variable "max_query_text_length" {
  type        = string
  description = "Sets the maximum query text length that will be saved; longer queries will be truncated."
  default     = "6000"
}

variable "postgresql_config" {
  type        = map(string)
  description = "A map of postgresql additional configuration parameters to values."
  default     = {}
}

locals {
 postgresql_config = merge({
    "pg_qs.track_utility"                   = var.track_utility
    "pg_qs.retention_period_in_days"        = var.retention_period_in_days
    "pg_qs.replace_parameter_placeholders"  = var.replace_parameter_placeholders
    "pg_qs.query_capture_mode"              = var.query_capture_mode
    "pg_qs.max_query_text_length"           = var.max_query_text_length
  }, var.postgresql_config)
}
