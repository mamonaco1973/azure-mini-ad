#!/bin/bash
# ==============================================================================
# validate.sh - Mini-AD Quick Start Validation (Azure)
# ------------------------------------------------------------------------------
# Purpose:
#   - Queries Azure for expected Mini-AD Quick Start resources and prints
#     quick-start endpoints for copy/paste access.
#
# Scope:
#   - Looks up Public IP DNS FQDNs created by Terraform:
#       - Windows AD admin host: win-ad-<suffix>
#       - Linux domain-joined host: linux-ad-<suffix>
#   - Optionally discovers the Key Vault name used for credentials.
#
# Fast-Fail Behavior:
#   - Script exits immediately on command failure, unset variables,
#     or failed pipelines.
#
# Requirements:
#   - Azure CLI installed and authenticated (az login).
#   - Resources deployed in the expected resource group.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
RESOURCE_GROUP="mcloud-project-rg"

WIN_LABEL_PREFIX="win-ad-"
LINUX_LABEL_PREFIX="linux-ad-"
KEYVAULT_PREFIX="ad-key-vault"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
az_trim() {
  # Trims whitespace/newlines from az output.
  xargs 2>/dev/null || true
}

get_public_fqdn_by_domain_label_prefix() {
  local rg="$1"
  local prefix="$2"

  az network public-ip list \
    --resource-group "${rg}" \
    --query "[?dnsSettings && starts_with(dnsSettings.domainNameLabel, '${prefix}')].dnsSettings.fqdn | [0]" \
    --output tsv | az_trim
}

get_key_vault_by_prefix() {
  local rg="$1"
  local prefix="$2"

  az keyvault list \
    --resource-group "${rg}" \
    --query "[?starts_with(name, '${prefix}')].name | [0]" \
    --output tsv | az_trim
}

# ------------------------------------------------------------------------------
# Lookups
# ------------------------------------------------------------------------------
windows_fqdn="$(get_public_fqdn_by_domain_label_prefix "${RESOURCE_GROUP}" "${WIN_LABEL_PREFIX}")"
linux_fqdn="$(get_public_fqdn_by_domain_label_prefix "${RESOURCE_GROUP}" "${LINUX_LABEL_PREFIX}")"
vault_name="$(get_key_vault_by_prefix "${RESOURCE_GROUP}" "${KEYVAULT_PREFIX}")"

# ------------------------------------------------------------------------------
# Quick Start Output
# ------------------------------------------------------------------------------
echo ""
echo "============================================================================"
echo "Mini-AD Quick Start - Validation Output (Azure)"
echo "============================================================================"
echo ""

echo "NOTE: Resource Group: ${RESOURCE_GROUP}"

if [ -n "${vault_name}" ] && [ "${vault_name}" != "None" ]; then
  echo "NOTE: Key Vault:      ${vault_name}"
else
  echo "WARN: Key Vault not found (prefix: ${KEYVAULT_PREFIX})"
fi

echo ""

if [ -n "${windows_fqdn}" ] && [ "${windows_fqdn}" != "None" ]; then
  echo "NOTE: Windows RDP Host FQDN: ${windows_fqdn}"
else
  echo "WARN: Windows host public FQDN not found (label prefix: ${WIN_LABEL_PREFIX})"
fi

if [ -n "${linux_fqdn}" ] && [ "${linux_fqdn}" != "None" ]; then
  echo "NOTE: Linux SSH Host FQDN:   ${linux_fqdn}"
else
  echo "WARN: Linux host public FQDN not found (label prefix: ${LINUX_LABEL_PREFIX})"
fi

echo ""
echo "NOTE: Validation complete."
echo ""
