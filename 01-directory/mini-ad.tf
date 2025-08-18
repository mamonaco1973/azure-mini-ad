# ==================================================================================================
# Network Interface and Linux VM Deployment
# Purpose:
#   - Create a dedicated NIC for the Samba-based Active Directory Domain Controller (AD DC).
#   - Provision an Ubuntu-based Linux VM configured as the AD DC.
#   - Ensure proper sequencing with Key Vault and DNS integration.
#
# Notes:
#   - Uses Ubuntu 24.04 LTS as the base image.
#   - Bootstraps Samba AD DC with a cloud-init script (`mini-ad.sh.template`).
#   - Relies on system-assigned managed identity for secure Key Vault access.
# ==================================================================================================

# --------------------------------------------------------------------------------------------------
# Create Network Interface (NIC) for the Linux VM
# --------------------------------------------------------------------------------------------------
resource "azurerm_network_interface" "mini_ad_vm_nic" {
  name                = "mini-ad-nic"                      # NIC resource name
  location            = azurerm_resource_group.ad.location # Same region as resource group
  resource_group_name = azurerm_resource_group.ad.name     # Same resource group

  # NIC IP configuration (internal/private use only)
  ip_configuration {
    name                          = "internal"                  # Config label
    subnet_id                     = azurerm_subnet.vm_subnet.id # Attach NIC to VM subnet
    private_ip_address_allocation = "Dynamic"                   # Auto-assign private IP
  }
}

# --------------------------------------------------------------------------------------------------
# Provision Linux Virtual Machine (Ubuntu 24.04 LTS)
# Acts as the Samba-based AD Domain Controller
# --------------------------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "mini_ad_instance" {
  name                            = "mini-ad-dc-${lower(var.netbios)}"       # VM name includes NetBIOS
  location                        = azurerm_resource_group.ad.location       # Same region
  resource_group_name             = azurerm_resource_group.ad.name           # Same resource group
  size                            = "Standard_B1s"                           # Small/cheap VM size (lab use)
  admin_username                  = "sysadmin"                               # Local admin account
  admin_password                  = random_password.sysadmin_password.result # Secure password from Key Vault
  disable_password_authentication = false                                    # Allow password login (lab convenience)

  # Attach NIC to VM
  network_interface_ids = [
    azurerm_network_interface.mini_ad_vm_nic.id
  ]

  # Configure OS Disk
  os_disk {
    caching              = "ReadWrite"    # Enable RW caching for faster access
    storage_account_type = "Standard_LRS" # Low-cost standard storage (locally redundant)
  }

  # Base OS image (Ubuntu 24.04 LTS from Canonical Marketplace)
  source_image_reference {
    publisher = "canonical"        # Ubuntu publisher
    offer     = "ubuntu-24_04-lts" # Ubuntu 24.04 LTS
    sku       = "server"           # Server SKU
    version   = "latest"           # Always use latest patch version
  }

  # Bootstrap configuration (cloud-init script encoded in base64)
  # Template injects variables such as domain details and admin passwords.
  custom_data = base64encode(templatefile("./scripts/mini-ad.sh.template", {
    HOSTNAME_DC        = "ad1"                                       # Hostname for DC
    DNS_ZONE           = var.dns_zone                                # DNS zone (e.g., mcloud.mikecloud.com)
    REALM              = var.realm                                   # Kerberos realm
    NETBIOS            = var.netbios                                 # NetBIOS name
    ADMINISTRATOR_PASS = random_password.admin_password.result        # AD Admin password
    ADMIN_USER_PASS    = random_password.admin_password.result        # Domain user password
    VAULT_NAME         = azurerm_key_vault.ad_key_vault.name          # Key Vault for secrets
  }))

  # Assign a managed identity so VM can securely fetch Key Vault secrets
  identity {
    type = "SystemAssigned"
  }

  # Ensure Key Vault exists before VM provisioning begins
  depends_on = [azurerm_key_vault.ad_key_vault]
}

# --------------------------------------------------------------------------------------------------
# Role Assignment: Grant Linux VM managed identity access to Key Vault secrets
# Role: "Key Vault Secrets Officer" → allows read/write of secrets
# --------------------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "vm_mini_ad_key_vault_secrets_user" {
  scope                = azurerm_key_vault.ad_key_vault.id                                       # Scope: Key Vault
  role_definition_name = "Key Vault Secrets Officer"                                             # Built-in Azure role
  principal_id         = azurerm_linux_virtual_machine.mini_ad_instance.identity[0].principal_id # VM managed identity
}

# ==================================================================================================
# DNS Integration
# Ensures the AD DC is fully operational before pointing VNet to it for DNS resolution.
# ==================================================================================================

# Wait for AD DC provisioning (Samba/DNS startup)
# Conservative 180s delay → adjust if bootstrap time differs.
resource "time_sleep" "wait_for_mini_ad" {
  depends_on      = [azurerm_linux_virtual_machine.mini_ad_instance]
  create_duration = "180s"
}

# Update Virtual Network DNS to point to the AD DC
# Required for domain joins and internal name resolution.
resource "azurerm_virtual_network_dns_servers" "mini_ad_dns_server" {
  virtual_network_id = azurerm_virtual_network.ad_vnet.id
  dns_servers        = [azurerm_network_interface.mini_ad_vm_nic.ip_configuration[0].private_ip_address]
  depends_on         = [time_sleep.wait_for_mini_ad]
}
