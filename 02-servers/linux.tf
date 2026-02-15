# ==============================================================================
# Linux VM: AD-Integrated Ubuntu Instance
# ------------------------------------------------------------------------------
# Provisions Ubuntu VM with password authentication.
# Stores credentials in Key Vault and assigns managed identity.
# Includes Public IP with DNS label based on vm_suffix.
# ==============================================================================


# ------------------------------------------------------------------------------
# Random Password: ubuntu
# ------------------------------------------------------------------------------
resource "random_password" "ubuntu_password" {

  length           = 24
  special          = true
  override_special = "!@#$%"
}


# ------------------------------------------------------------------------------
# Key Vault Secret: ubuntu credentials
# ------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "ubuntu_secret" {

  name = "ubuntu-credentials"

  value = jsonencode({
    username = "ubuntu"
    password = random_password.ubuntu_password.result
  })

  key_vault_id = data.azurerm_key_vault.ad_key_vault.id
  content_type = "application/json"
}


# ------------------------------------------------------------------------------
# Public IP
# ------------------------------------------------------------------------------
resource "azurerm_public_ip" "linux_vm_pip" {

  name                = "linux-ad-pip-${random_string.vm_suffix.result}"
  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name

  allocation_method = "Static"
  sku               = "Standard"

  domain_name_label = "linux-ad-${random_string.vm_suffix.result}"
}


# ------------------------------------------------------------------------------
# Network Interface
# ------------------------------------------------------------------------------
resource "azurerm_network_interface" "linux_vm_nic" {

  name                = "linux-vm-nic"
  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux_vm_pip.id
  }
}


# ------------------------------------------------------------------------------
# Linux Virtual Machine
# ------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "linux_ad_instance" {

  name                = "linux-ad-${random_string.vm_suffix.result}"

  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name
  size                = "Standard_B1s"

  admin_username                  = "ubuntu"
  admin_password                  = random_password.ubuntu_password.result
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.linux_vm_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(templatefile(
    "./scripts/custom_data.sh",
    {
      vault_name  = data.azurerm_key_vault.ad_key_vault.name
      domain_fqdn = var.dns_zone
    }
  ))

  identity {
    type = "SystemAssigned"
  }
}


# ------------------------------------------------------------------------------
# RBAC: VM Managed Identity Access to Key Vault
# ------------------------------------------------------------------------------
resource "azurerm_role_assignment" "vm_lnx_key_vault_secrets_user" {

  scope                = data.azurerm_key_vault.ad_key_vault.id
  role_definition_name = "Key Vault Secrets User"

  principal_id = azurerm_linux_virtual_machine.linux_ad_instance.identity[0].principal_id
}
