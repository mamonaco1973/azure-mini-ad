# ==============================================================================
# Active Directory Naming Inputs
# ------------------------------------------------------------------------------
# Defines DNS, Kerberos, and NetBIOS naming for AD domain.
# ==============================================================================


# ------------------------------------------------------------------------------
# DNS Zone (FQDN)
# ------------------------------------------------------------------------------
# Fully qualified domain name for Active Directory.
# Used for DNS namespace and domain identity.
# ------------------------------------------------------------------------------
variable "dns_zone" {

  description = "AD DNS zone (e.g., mcloud.mikecloud.com)."
  type        = string
  default     = "mcloud.mikecloud.com"
}


# ------------------------------------------------------------------------------
# Kerberos Realm (Uppercase)
# ------------------------------------------------------------------------------
# Typically matches dns_zone in uppercase.
# Required for Kerberos authentication configuration.
# ------------------------------------------------------------------------------
variable "realm" {

  description = "Kerberos realm (e.g., MCLOUD.MIKECLOUD.COM)."

  type    = string
  default = "MCLOUD.MIKECLOUD.COM"
}


# ------------------------------------------------------------------------------
# NetBIOS Domain Name
# ------------------------------------------------------------------------------
# Short domain name (<= 15 characters).
# Used by legacy systems and SMB protocols.
# ------------------------------------------------------------------------------
variable "netbios" {

  description = "NetBIOS short name (e.g., MCLOUD)."
  type        = string
  default     = "MCLOUD"
}
