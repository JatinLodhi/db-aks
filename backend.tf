# Remote state using Azure Storage.
# Terraform workspaces automatically isolate state:
#   dev  → aks.tfstate/dev/terraform.tfstate
#   uat  → aks.tfstate/uat/terraform.tfstate
#   prod → aks.tfstate/prod/terraform.tfstate
#
# One-time setup (run once per subscription):
#   az group create --name terraform-state-rg --location eastus
#   az storage account create --name tfstateaks<suffix> \
#     --resource-group terraform-state-rg --sku Standard_LRS
#   az storage container create --name tfstate \
#     --account-name tfstateaks<suffix>
#
# Then update storage_account_name below and run:
#   terraform init
#
# For LOCAL backend (no Azure storage), comment out this block.
# State will be stored in terraform.tfstate.d/<workspace>/terraform.tfstate

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateaks" # REPLACE with your globally unique storage account name
    container_name       = "tfstate"
    key                  = "aks.tfstate"
    # access_key is passed via -backend-config or BACKEND_STORAGE_ACCESS_KEY in CI
  }
}
