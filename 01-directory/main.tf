# ==============================================================================
# Azure Provider Configuration
# ------------------------------------------------------------------------------
# Configures AzureRM provider and feature behavior.
# Enables Key Vault purge and allows RG deletion with resources.
# ==============================================================================

provider "azurerm" {

  features {

    # Key Vault feature configuration.
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }

    # Resource group feature configuration.
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}


# ==============================================================================
# Data Sources
# ------------------------------------------------------------------------------
# Retrieves subscription and current client configuration details.
# ==============================================================================

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}


# ==============================================================================
# Variables
# ------------------------------------------------------------------------------
# Defines resource group name and deployment region.
# ==============================================================================

variable "resource_group_name" {
  description = "Azure resource group name."
  type        = string
  default     = "mcloud-project-rg"
}

variable "resource_group_location" {
  description = "Azure region for resource group."
  type        = string
  default     = "Central US"
}


# ==============================================================================
# Resource Group
# ------------------------------------------------------------------------------
# Creates resource group to contain all AD-related resources.
# ==============================================================================

resource "azurerm_resource_group" "ad" {

  name     = var.resource_group_name
  location = var.resource_group_location
}
