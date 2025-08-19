module "mini_ad" {
  source            = "../modules/mini-ad"
  location          = var.location
  netbios           = var.netbios
  vnet_id           = azurerm_virtual_network.ad_vnet.id
  realm             = var.realm
  users_json        = ""
  user_base_dn      = var.user_base_dn
  ad_admin_password = random_password.admin_password.result
  dns_zone          = var.dns_zone
  subnet_id         = azurerm_subnet.mini_ad_subnet.id
  admin_password    = random_password.sysadmin_password.result
}
