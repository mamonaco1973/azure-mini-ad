# ==============================================================================
# Azure Bastion Network Security Group
# ------------------------------------------------------------------------------
# Defines NSG rules required for Azure Bastion.
# Includes inbound management access and outbound connectivity.
# ==============================================================================

resource "azurerm_network_security_group" "bastion-nsg" {

  name                = "bastion-nsg"
  location            = azurerm_resource_group.ad.location
  resource_group_name = azurerm_resource_group.ad.name

  # ---------------------------------------------------------------------------
  # Inbound: Gateway Manager
  # ---------------------------------------------------------------------------
  security_rule {
    name                       = "GatewayManager"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  # ---------------------------------------------------------------------------
  # Inbound: Internet to Bastion Public IP
  # ---------------------------------------------------------------------------
  security_rule {
    name                       = "Internet-Bastion-PublicIP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ---------------------------------------------------------------------------
  # Outbound: Virtual Network
  # ---------------------------------------------------------------------------
  security_rule {
    name                       = "OutboundVirtualNetwork"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  # ---------------------------------------------------------------------------
  # Outbound: Azure Cloud
  # ---------------------------------------------------------------------------
  security_rule {
    name                       = "OutboundToAzureCloud"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
}


# ==============================================================================
# Azure Bastion Public IP
# ------------------------------------------------------------------------------
# Creates static Standard SKU public IP required for Bastion.
# ==============================================================================

resource "azurerm_public_ip" "bastion-ip" {

  name                = "bastion-public-ip"
  location            = azurerm_resource_group.ad.location
  resource_group_name = azurerm_resource_group.ad.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


# ==============================================================================
# Azure Bastion Host
# ------------------------------------------------------------------------------
# Deploys Azure Bastion into dedicated subnet.
# Associates public IP and IP configuration.
# ==============================================================================

resource "azurerm_bastion_host" "bastion-host" {

  name                = "bastion-host"
  location            = azurerm_resource_group.ad.location
  resource_group_name = azurerm_resource_group.ad.name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-ip.id
  }
}
