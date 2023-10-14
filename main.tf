resource "azurerm_resource_group" "amran-rg" {
  name     = var.resource_group_name
  location = var.resource_group_location

  tags = {
    environment = "preproduction"
  }
}

locals  {
app_name_prefix = "amrandemoapp"
}

# Virtual Network
resource "azurerm_virtual_network" "app-service-vnet" {
  name                = "amran-app-service-vnet"
  resource_group_name = azurerm_resource_group.amran-rg.name
  location            = azurerm_resource_group.amran-rg.location
  address_space       = ["10.4.0.0/16"]
}

# Subnets for App Service instances
resource "azurerm_subnet" "appserv" {
  name                 = "frontend-app"
  resource_group_name  = azurerm_resource_group.amran-rg.name
  virtual_network_name = azurerm_virtual_network.app-service-vnet.name
  address_prefixes     = ["10.4.1.0/24"]
  private_link_service_network_policies_enabled = false
  private_endpoint_network_policies_enabled = false

    delegation {
    name = "service-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
# Subnets for private Endpoint
resource "azurerm_subnet" "plink-endpoint-subnet" {
  name                 = "amran-plink-endpoint-subnet"
  resource_group_name  = azurerm_resource_group.amran-rg.name
  virtual_network_name = azurerm_virtual_network.app-service-vnet.name
  address_prefixes     = ["10.4.2.0/24"]
  private_link_service_network_policies_enabled = false
  private_endpoint_network_policies_enabled = false
}

# App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.amran-rg.name
  location            = azurerm_resource_group.amran-rg.location
  sku_name            = "P0v3"
  os_type             = "Linux"  
}

# Main App Service
resource "azurerm_linux_web_app" "app" {
  name                = "amranwebapp-01357"
  resource_group_name = azurerm_resource_group.amran-rg.name
  location            = azurerm_resource_group.amran-rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      dotnet_version = "7.0"
    }
  }
  
  app_settings = {
    "SOME_KEY" = "some-value"
  }
  

  connection_string {
    name  = "Database"
    type  = "SQLAzure"
    value = "Server=tcp:azurerm_mssql_server.sql.fully_qualified_domain_name Database=azurerm_mssql_database.db.name;User ID=azurerm_mssql_server.sql.administrator_login;Password=azurerm_mssql_server.sql.administrator_login_password;Trusted_Connection=False;Encrypt=True;"
  }
}

# azurerm_app_service_virtual_network_swift_connection
resource "azurerm_app_service_virtual_network_swift_connection" "swift-connect-vnet" {
  app_service_id = azurerm_linux_web_app.app.id
  subnet_id      = azurerm_subnet.appserv.id
}

# Create private Endpoint and associate with Azure Web App


resource "azurerm_private_endpoint" "plink-endpoint" {
  name                = "amran-plink-endpoint"
  location            = azurerm_resource_group.amran-rg.location
  resource_group_name = azurerm_resource_group.amran-rg.name
  subnet_id           = azurerm_subnet.plink-endpoint-subnet.id

  private_service_connection {
    name                           = "amran-web-private-service-connection"
    private_connection_resource_id = azurerm_linux_web_app.app.id
    subresource_names = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "amran-private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.pdns-zone.id]
  }
}

resource "azurerm_private_dns_zone" "pdns-zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.amran-rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "plink-vnet-link" {
  name                  = "amran-plink-vnet-link"
  resource_group_name   = azurerm_resource_group.amran-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pdns-zone.name
  virtual_network_id    = azurerm_virtual_network.app-service-vnet.id
  registration_enabled = false
}

# Create MS SQL Server
resource "azurerm_mssql_server" "sql" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.amran-rg.name
  location                     = azurerm_resource_group.amran-rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

# Create MS SQL Server database
resource "azurerm_mssql_database" "db" {
  name           = "ProductsDB"
  server_id      = azurerm_mssql_server.sql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  sku_name       = "S0"
  zone_redundant = false
}

# Create Azure Web App storage
resource "azurerm_storage_account" "storage" {
  name                     = "amranstgaccount"
  resource_group_name      = azurerm_resource_group.amran-rg.name
  location                 = azurerm_resource_group.amran-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_mssql_database_extended_auditing_policy" "policy" {
  database_id                             = azurerm_mssql_database.db.id
  storage_endpoint                        = azurerm_storage_account.storage.primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.storage.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 1
}

# Subnets for App Service and app gateway
resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  resource_group_name = azurerm_resource_group.amran-rg.name
  location            = azurerm_resource_group.amran-rg.location
  address_space       = ["10.21.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "myAGSubnet"
  resource_group_name  = azurerm_resource_group.amran-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.21.0.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "myBackendSubnet"
  resource_group_name  = azurerm_resource_group.amran-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.21.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "myAGPublicIPAddress"
  resource_group_name = azurerm_resource_group.amran-rg.name
  location            = azurerm_resource_group.amran-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create App Gateway
resource "azurerm_application_gateway" "main" {
  name                = "myAppGateway"
  resource_group_name = azurerm_resource_group.amran-rg.name
  location            = azurerm_resource_group.amran-rg.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  waf_configuration {
    enabled          = "true"
    firewall_mode    = "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.0"
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = var.backend_address_pool_name
    fqdns = ["${azurerm_linux_web_app.app.name}.azurewebsites.net"]

  }

  backend_http_settings {
    name                  = var.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = var.listener_name
    backend_address_pool_name  = var.backend_address_pool_name
    backend_http_settings_name = var.http_setting_name
    priority                   = 1
  }
}

# private service connection and load balancer

resource "azurerm_resource_group" "plink-rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "plink-vnet" {
  name                = "demo-plink-vnet"
  address_space       = ["10.5.0.0/16"]
  location            = azurerm_resource_group.plink-rg.location
  resource_group_name = azurerm_resource_group.plink-rg.name
}

resource "azurerm_subnet" "plink-subnet" {
  name                 = "amran-plink-subnet"
  resource_group_name  = azurerm_resource_group.plink-rg.name
  virtual_network_name = azurerm_virtual_network.plink-vnet.name
  address_prefixes     = ["10.5.1.0/24"]
  private_link_service_network_policies_enabled = false
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_public_ip" "plink-pip" {
  name                = "amran-plink--pip"
  sku                 = "Standard"
  location            = azurerm_resource_group.plink-rg.location
  resource_group_name = azurerm_resource_group.plink-rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "plink-lb" {
  name                = "amran-plink-lb"
  sku                 = "Standard"
  location            = azurerm_resource_group.plink-rg.location
  resource_group_name = azurerm_resource_group.plink-rg.name

  frontend_ip_configuration {
    name                 = azurerm_public_ip.plink-pip.name
    public_ip_address_id = azurerm_public_ip.plink-pip.id
  }
}

resource "azurerm_private_link_service" "plink-service-connection" {
  name                = "amran-plink-service-connection"
  location            = azurerm_resource_group.plink-rg.location
  resource_group_name = azurerm_resource_group.plink-rg.name
    
  nat_ip_configuration {
    name      = azurerm_public_ip.plink-pip.name
    primary   = true
    subnet_id = azurerm_subnet.plink-subnet.id
  }

  load_balancer_frontend_ip_configuration_ids = [
    azurerm_lb.plink-lb.frontend_ip_configuration.0.id,
  ]
}