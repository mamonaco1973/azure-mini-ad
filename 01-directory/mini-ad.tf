# --- Create a network interface (NIC) for the Linux VM ---
resource "azurerm_network_interface" "mini_ad_vm_nic" {
  name                = "mini-ad-nic"                      # NIC name
  location            = azurerm_resource_group.ad.location # Place NIC in the same region as the resource group
  resource_group_name = azurerm_resource_group.ad.name     # Place NIC in the same resource group

  # --- Configure the NIC's IP settings ---
  ip_configuration {
    name                          = "internal"                  # IP configuration name
    subnet_id                     = azurerm_subnet.vm_subnet.id # Connect to existing subnet (data source)
    private_ip_address_allocation = "Dynamic"                   # Dynamically assign private IP
  }
}

# --- Provision the actual Linux Virtual Machine ---
resource "azurerm_linux_virtual_machine" "mini_ad_instance" {
  name                            = "mini-ad-dc-${lower(var.netbios)}"       # Name of AD controller
  location                        = azurerm_resource_group.ad.location       # Same location as resource group
  resource_group_name             = azurerm_resource_group.ad.name           # Same resource group
  size                            = "Standard_B1s"                           # Small VM size (for test/dev)
  admin_username                  = "sysadmin"                               # Admin username
  admin_password                  = random_password.sysadmin_password.result # Use generated password
  disable_password_authentication = false                                    # Explicitly allow password auth

  # --- Attach the previously created network interface to the VM ---
  network_interface_ids = [
    azurerm_network_interface.mini_ad_vm_nic.id
  ]

  # --- Configure the OS disk ---
  os_disk {
    caching              = "ReadWrite"    # Enable read/write caching
    storage_account_type = "Standard_LRS" # Use locally redundant standard storage
  }

  # --- Use an official Ubuntu image from the Azure Marketplace ---
  source_image_reference {
    publisher = "canonical"        # Publisher = Canonical (Ubuntu maintainers)
    offer     = "ubuntu-24_04-lts" # Offer = Ubuntu 24.04 LTS
    sku       = "server"           # SKU = Server (standard edition)
    version   = "latest"           # Use the latest version available
  }

  custom_data = base64encode(templatefile("./scripts/mini-ad.sh.template", {
    HOSTNAME_DC        = "ad1"
    DNS_ZONE           = var.dns_zone
    REALM              = var.realm
    NETBIOS            = var.netbios
    ADMINISTRATOR_PASS = random_password.admin_password.result
    ADMIN_USER_PASS    = random_password.admin_password.result
    VAULT_NAME         = azurerm_key_vault.ad_key_vault.name
  }))

  # --- Assign a system-assigned managed identity to the VM ---
  identity {
    type = "SystemAssigned"
  }

  # --- Explicit dependency to ensure the Windows VM extension completes first ---
  # This ensures that if this VM relies on domain services from the Windows VM, the domain join script runs first.
  depends_on = [azurerm_key_vault.ad_key_vault]
}

# --- Grant the Linux VM's managed identity permission to read secrets from Key Vault ---
resource "azurerm_role_assignment" "vm_mini_ad_key_vault_secrets_user" {
  scope                = azurerm_key_vault.ad_key_vault.id                                       # Target the Key Vault itself
  role_definition_name = "Key Vault Secrets Officer"                                             # Predefined Azure role that allows reading secrets
  principal_id         = azurerm_linux_virtual_machine.mini_ad_instance.identity[0].principal_id # Managed identity of this VM
}


# ==================================================================================================
# Delay to allow the DC to finish provisioning (Samba/DNS up) before associating DHCP options
# Adjust duration to your bootstrap time; 180s is a conservative lab default
# ==================================================================================================
resource "time_sleep" "wait_for_mini_ad" {
  depends_on      = [azurerm_linux_virtual_machine.mini_ad_instance]
  create_duration = "180s"
}

# Update the DNS servers for the existing VNet
resource "azurerm_virtual_network_dns_servers" "aadds_dns_servers" {
  virtual_network_id = azurerm_virtual_network.ad_vnet.id
  dns_servers        = [azurerm_network_interface.mini_ad_vm_nic.ip_configuration[0].private_ip_address]
  depends_on         = [time_sleep.wait_for_mini_ad]
}



