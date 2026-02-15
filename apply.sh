#!/bin/bash
# ==============================================================================
# Mini Active Directory Bootstrap Script (Azure)
# ------------------------------------------------------------------------------
# Validates environment and deploys AD infrastructure in two phases:
#   1. Directory layer (Key Vault and base resources).
#   2. Server layer (Linux VM, Samba AD, domain config).
#
# Requirements:
#   - Azure CLI authenticated.
#   - Terraform installed.
#   - check_env.sh available.
# ==============================================================================

set -e


# ------------------------------------------------------------------------------
# Pre-Flight Validation
# ------------------------------------------------------------------------------
# Ensure Azure CLI, Terraform, and required variables are ready.
# ------------------------------------------------------------------------------
./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi


# ------------------------------------------------------------------------------
# Phase 1: Directory Layer
# ------------------------------------------------------------------------------
# Deploy Key Vault and foundational AD infrastructure.
# ------------------------------------------------------------------------------
cd 01-directory

terraform init
terraform apply -auto-approve

if [ $? -ne 0 ]; then
  echo "ERROR: Terraform apply failed in 01-directory."
  exit 1
fi

cd ..


# ------------------------------------------------------------------------------
# Phase 2: Server Layer
# ------------------------------------------------------------------------------
# Deploy Samba-based AD controller.
# Discover Key Vault name and pass to Terraform.
# ------------------------------------------------------------------------------
cd 02-servers

vault=$(az keyvault list \
  --resource-group mcloud-project-rg \
  --query "[?starts_with(name, 'ad-key-vault')].name | [0]" \
  --output tsv)

echo "NOTE: Key vault for secrets is $vault"

terraform init
terraform apply -var="vault_name=$vault" -auto-approve

cd ..

# ------------------------------------------------------------------------------
# Build Validation
# ------------------------------------------------------------------------------
echo "NOTE: Running post-build validation..."

./validate.sh
