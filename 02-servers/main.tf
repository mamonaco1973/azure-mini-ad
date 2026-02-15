# ==============================================================================
# Azure Provider Configuration
# ------------------------------------------------------------------------------
# Configures AzureRM provider and Key Vault feature behavior.
# ==============================================================================

provider "azurerm" {

  features {

    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
  }
}


# ==============================================================================
# Data Sources: Subscription and Client Context
# ------------------------------------------------------------------------------
# Retrieves current subscription and authenticated identity details.
# ==============================================================================

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}


# ==============================================================================
# Variables
# ------------------------------------------------------------------------------
# Defines resource group and Key Vault inputs.
# ==============================================================================

variable "resource_group_name" {

  description = "Azure resource group name."
  type        = string
  default     = "mcloud-project-rg"
}

variable "vault_name" {

  description = "Name of the Key Vault."
  type        = string
}


# ==============================================================================
# Data Source: Resource Group
# ------------------------------------------------------------------------------
# Retrieves existing resource group metadata.
# ==============================================================================

data "azurerm_resource_group" "ad" {

  name = var.resource_group_name
}


# ==============================================================================
# Data Source: VM Subnet
# ------------------------------------------------------------------------------
# Retrieves subnet used for VM network interfaces.
# ==============================================================================

data "azurerm_subnet" "vm_subnet" {

  name                 = "vm-subnet"
  resource_group_name  = data.azurerm_resource_group.ad.name
  virtual_network_name = "ad-vnet"
}


# ==============================================================================
# Data Source: Existing Key Vault
# ------------------------------------------------------------------------------
# Retrieves existing Key Vault for secret access.
# ==============================================================================

data "azurerm_key_vault" "ad_key_vault" {

  name                = var.vault_name
  resource_group_name = var.resource_group_name
}
