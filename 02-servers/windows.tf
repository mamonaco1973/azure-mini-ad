# ==============================================================================
# Windows VM: AD Management Instance
# ------------------------------------------------------------------------------
# Provisions Windows Server VM.
# Generates admin credentials and stores them in Key Vault.
# Now includes Public IP + DNS label derived from vm_suffix using the *old*
# NIC IP configuration pattern (separate association resource).
# ==============================================================================


# ------------------------------------------------------------------------------
# Random Password: adminuser
# ------------------------------------------------------------------------------
resource "random_password" "win_adminuser_password" {

  length           = 24
  special          = true
  override_special = "!@#$%"
}


# ------------------------------------------------------------------------------
# Random String: VM Suffix
# ------------------------------------------------------------------------------
resource "random_string" "vm_suffix" {

  length  = 6
  special = false
  upper   = false
}


# ------------------------------------------------------------------------------
# Key Vault Secret: Windows Admin Credentials
# ------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "win_adminuser_secret" {

  name = "win-adminuser-credentials"

  value = jsonencode({
    username = "adminuser"
    password = random_password.win_adminuser_password.result
  })

  key_vault_id = data.azurerm_key_vault.ad_key_vault.id
  content_type = "application/json"
}


# ------------------------------------------------------------------------------
# Public IP
# ------------------------------------------------------------------------------
resource "azurerm_public_ip" "windows_vm_pip" {

  name                = "win-ad-pip-${random_string.vm_suffix.result}"
  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name

  allocation_method = "Static"
  sku               = "Standard"

  domain_name_label = "win-ad-${random_string.vm_suffix.result}"
}


# ------------------------------------------------------------------------------
# Network Interface
# ------------------------------------------------------------------------------
resource "azurerm_network_interface" "windows_vm_nic" {

  name                = "windows-vm-nic"
  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


# ------------------------------------------------------------------------------
# Public IP Association
# ------------------------------------------------------------------------------
resource "azurerm_network_interface_public_ip_address_association" "windows_vm_pip_assoc" {

  network_interface_id  = azurerm_network_interface.windows_vm_nic.id
  ip_configuration_name = "internal"
  public_ip_address_id  = azurerm_public_ip.windows_vm_pip.id
}


# ------------------------------------------------------------------------------
# Windows Virtual Machine
# ------------------------------------------------------------------------------
resource "azurerm_windows_virtual_machine" "windows_ad_instance" {

  name = "win-ad-${random_string.vm_suffix.result}"

  location            = data.azurerm_resource_group.ad.location
  resource_group_name = data.azurerm_resource_group.ad.name
  size                = "Standard_DS1_v2"

  admin_username = "adminuser"
  admin_password = random_password.win_adminuser_password.result

  network_interface_ids = [
    azurerm_network_interface.windows_vm_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}


# ------------------------------------------------------------------------------
# RBAC: VM Access to Key Vault
# ------------------------------------------------------------------------------
resource "azurerm_role_assignment" "vm_win_key_vault_secrets_user" {

  scope                = data.azurerm_key_vault.ad_key_vault.id
  role_definition_name = "Key Vault Secrets User"

  principal_id = azurerm_windows_virtual_machine.windows_ad_instance.identity[0].principal_id
}


# ------------------------------------------------------------------------------
# VM Extension: AD Join Script
# ------------------------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "join_script" {

  name               = "customScript"
  virtual_machine_id = azurerm_windows_virtual_machine.windows_ad_instance.id

  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
{
  "fileUris": [
    "https://${azurerm_storage_account.scripts_storage.name}.blob.core.windows.net/${azurerm_storage_container.scripts.name}/${azurerm_storage_blob.ad_join_script.name}?${data.azurerm_storage_account_sas.script_sas.sas}"
  ],
  "commandToExecute":
    "powershell.exe -ExecutionPolicy Unrestricted -File ad-join.ps1 *>> C:\\WindowsAzure\\Logs\\ad-join.log"
}
SETTINGS

  depends_on = [
    azurerm_role_assignment.vm_win_key_vault_secrets_user
  ]
}
