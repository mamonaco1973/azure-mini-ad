output "resource_group_name" {
  description = "Name of the mini-ad resource group."
  value       = azurerm_resource_group.mini_ad_rg.name
}

output "resource_group_location" {
  description = "Azure region of the mini-ad resource group."
  value       = azurerm_resource_group.mini_ad_rg.location
}
