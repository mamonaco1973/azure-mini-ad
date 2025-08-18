#!/bin/bash

set -e

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

cd 01-directory

terraform init
terraform apply -auto-approve

if [ $? -ne 0 ]; then
  echo "ERROR: Terraform apply failed in 01-directory. Exiting."
  exit 1
fi
cd ..

cd 02-servers

vault=$(az keyvault list --resource-group mini-ad-rg --query "[?starts_with(name, 'ad-key-vault')].name | [0]" --output tsv)
echo "NOTE: Key vault for secrets is $vault"
terraform init
terraform apply -var="vault_name=$vault" -auto-approve

cd ..

