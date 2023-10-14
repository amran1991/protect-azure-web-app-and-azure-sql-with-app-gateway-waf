variable "resource_group_name" {
  type        = string
  description = "RG name in Azure"
}

variable "resource_group_location" {
  type        = string
  description = "RG location in Azure"
}

variable "sql_server_name" {
  type        = string
  description = "SQL Server instance name in Azure"
}

variable "sql_database_name" {
  type        = string
  description = "SQL Database name in Azure"
}

variable "sql_admin_login" {
  type        = string
  description = "SQL Server login name in Azure"
}

variable "sql_admin_password" {
  type        = string
  description = "SQL Server password name in Azure"
}

variable "firewall_name" {
  description = "The name of the Azure Firewall."
}

variable "app_gateway_name" {
  description = "The name of the Azure Application Gateway."
}

variable "app_service_plan_name" {
  type        = string
  description = "App Service Plan name in Azure"
}

variable "app_service_name" {
  type        = string
  description = "App Service name in Azure"
}

variable "app_service_plan_id" {
  description = "The ID of the Azure App Service Plan for the Web App."
}

variable "public_ip_name" {
  description = "The name of the Azure Public IP."
}

variable "vnet_name" {
  description = "The name of the Virtual Network."
}

variable "subnet_name" {
  description = "The name of the Subnet."
}

variable "subnet_address_prefix" {
  description = "The address prefix of the Subnet."
}

variable "backend_address_pool_name" {
    default = "demo-project-BackendPool"
}

variable "frontend_port_name" {
    default = "demo-project-FrontendPort"
}

variable "frontend_ip_configuration_name" {
    default = "demo-project-AGIPConfig"
}

variable "http_setting_name" {
    default = "demo-project-HTTPsetting"
}

variable "listener_name" {
    default = "demo-project-Listener"
}

variable "request_routing_rule_name" {
    default = "demo-project-RoutingRule"
}