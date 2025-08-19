module "mini_ad" {
  source            = "../modules/mini-ad"
  location          = var.resource_group_location
  netbios           = var.netbios
  vnet_id           = azurerm_virtual_network.ad_vnet.id
  realm             = var.realm
  users_json        = locals.users_json
  user_base_dn      = var.user_base_dn
  ad_admin_password = random_password.admin_password.result
  dns_zone          = var.dns_zone
  subnet_id         = azurerm_subnet.mini_ad_subnet.id
  admin_password    = random_password.sysadmin_password.result
}


# -------------------------------------------------------------------
# Local variable: users_json
# - Renders a JSON template file (`users.json.template`)
# - Injects dynamically generated random passwords into the template
# - Produces a single JSON blob you can pass into VM bootstrap
# -------------------------------------------------------------------
locals {
  users_json = templatefile("./scripts/users.json.template", {
    USER_BASE_DN    = var.user_base_dn                       # User base DN for LDAP
    DNS_ZONE        = var.dns_zone                           # DNS zone (e.g., mcloud.mikecloud.com)
    REALM           = var.realm                              # Kerberos realm
    NETBIOS         = var.netbios                            # NetBIOS name
    jsmith_password = random_password.jsmith_password.result # Insert John Smith's random password
    edavis_password = random_password.edavis_password.result # Insert Emily Davis's random password
    rpatel_password = random_password.rpatel_password.result # Insert Raj Patel's random password
    akumar_password = random_password.akumar_password.result # Insert Amit Kumar's random password
  })
}
