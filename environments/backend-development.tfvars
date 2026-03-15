# Backend Configuration for Development Environment
# Store this file securely - do not commit with actual values

resource_group_name  = "terraform-state-rg"
storage_account_name = "tfstateaksdev"
container_name       = "tfstate"
key                  = "development.tfstate"
