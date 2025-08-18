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

  #   # --- Pass custom data (cloud-init) to the VM at creation ---
  #   # This template can contain any necessary setup like installing packages or configuring domain joins
  #   custom_data = base64encode(templatefile("./scripts/custom_data.sh", {
  #     vault_name  = data.azurerm_key_vault.ad_key_vault.name    # Inject Key Vault name into the script
  #     domain_fqdn = "mcloud.mikecloud.com"                      # Inject domain FQDN into the script
  #   }))

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
