
#!/bin/bash

set -e

cd 02-servers

vault=$(az keyvault list --resource-group mini-ad-rg --query "[?starts_with(name, 'ad-key-vault')].name | [0]" --output tsv)
echo "NOTE: Key vault for secrets is $vault"
terraform init
terraform destroy -var="vault_name=$vault" -auto-approve

cd ..

cd 01-directory

terraform init
terraform destroy -auto-approve

cd ..


