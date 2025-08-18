# ==================================================================================================
# Network Security Group: mini-ad-nsg
# Purpose: Allow all required ports for a Samba-based Active Directory Domain Controller.
# NOTE: Currently open to all IPv4 (0.0.0.0/0) for simplicity — secure this in production.
# ==================================================================================================

resource "azurerm_network_security_group" "mini_ad_nsg" {
  name                = "mini-ad-nsg"
  location            = azurerm_resource_group.ad.location
  resource_group_name = azurerm_resource_group.ad.name

  # DNS (TCP/UDP 53)
  security_rule {
    name                       = "DNS-TCP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "DNS-UDP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Kerberos (TCP/UDP 88)
  security_rule {
    name                       = "Kerberos-TCP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "88"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Kerberos-UDP"
    priority                   = 111
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    destination_port_range     = "88"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # LDAP (TCP/UDP 389)
  security_rule {
    name                       = "LDAP-TCP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "LDAP-UDP"
    priority                   = 121
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    destination_port_range     = "389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SMB/CIFS (TCP 445)
  security_rule {
    name                       = "SMB"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "445"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Kerberos Password Change (TCP/UDP 464)
  security_rule {
    name                       = "KerberosPwd-TCP"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "464"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "KerberosPwd-UDP"
    priority                   = 141
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    destination_port_range     = "464"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # RPC Endpoint Mapper (TCP 135)
  security_rule {
    name                       = "RPC-135"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "135"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTPS (TCP 443)
  security_rule {
    name                       = "HTTPS"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # LDAPS (TCP 636)
  security_rule {
    name                       = "LDAPS"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "636"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Global Catalog (TCP 3268, 3269)
  security_rule {
    name                       = "GC-3268"
    priority                   = 180
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "3268"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "GC-3269"
    priority                   = 181
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "3269"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Ephemeral RPC Ports (TCP 49152–65535)
  security_rule {
    name                       = "Ephemeral-RPC"
    priority                   = 190
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_ranges    = ["49152-65535"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # NTP (UDP 123)
  security_rule {
    name                       = "NTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    destination_port_range     = "123"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow all outbound
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "mini-ad-nsg"
  }
}

# Associate NSG with the mini-AD subnet
resource "azurerm_subnet_network_security_group_association" "mini_ad_subnet_assoc" {
  subnet_id                 = azurerm_subnet.mini_ad_subnet.id
  network_security_group_id = azurerm_network_security_group.mini_ad_nsg.id
}


