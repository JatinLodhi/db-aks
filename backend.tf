# backend.tf
# Configure remote state storage in Azure Storage Account
# This ensures state is shared and locked across team members

# Uncomment the terraform block below and configure the values to use remote state
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "terraform-state-rg"
#     storage_account_name = "tfstateaksprod"
#     container_name       = "tfstate"
#     key                  = "aks-production.tfstate"
#
#     # Optional: Use managed identity for authentication
#     # use_msi = true
#
#     # Or use Azure CLI authentication (default)
#   }
# }
#
# 2. Create a storage account (must be globally unique)
#    az storage account create \
#      --resource-group terraform-state-rg \
#      --name tfstateaksprod \
#      --sku Standard_LRS \
#      --encryption-services blob
#
# 3. Create a container
#    az storage container create \
#      --name tfstate \
#      --account-name tfstateaksprod
#
# 4. Uncomment the backend configuration above and update values
#
# 5. Initialize Terraform with the backend
#    terraform init -backend-config="resource_group_name=terraform-state-rg" \
#                   -backend-config="storage_account_name=tfstateaksprod" \
#                   -backend-config="container_name=tfstate" \
#                   -backend-config="key=aks-production.tfstate"

# Security Best Practices:
# - Enable soft delete on the storage account
# - Enable versioning for state files
# - Use access keys or managed identities, not SAS tokens
# - Limit access to state storage with Azure RBAC
# - Enable Azure Storage firewall rules
