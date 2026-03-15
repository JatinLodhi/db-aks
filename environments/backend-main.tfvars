# Backend Configuration for Production Environment
# Store this file securely - do not commit with actual values

resource_group_name  = "terraform-state-rg"
storage_account_name = "tfstateaksprod"
container_name       = "tfstate"
key                  = "main.tfstate"
