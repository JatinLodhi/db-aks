locals {
  # All environment-specific configuration keyed by workspace name.
  # Switch environments with: terraform workspace select dev|uat|prod
  # Creating a new workspace: terraform workspace new dev
  #
  # If an unsupported workspace is selected, Terraform will error here with
  # "The given key does not identify an element in this collection value".

  env_config = {

    # ─────────────────────────────────────────────────────────────────────────
    # DEVELOPMENT
    # ─────────────────────────────────────────────────────────────────────────
    dev = {
      resource_group_name = "aks-dev-rg"
      cluster_name        = "aks-dev-cluster"
      location            = "eastus"
      environment         = "development"
      kubernetes_version  = "1.31"
      sku_tier            = "Standard"

      # System node pool
      system_node_vm_size   = "Standard_D2s_v5" # 2 vCPU / 8 GB — smaller for dev cost
      system_node_count     = 2
      system_node_min_count = 2
      system_node_max_count = 4

      # Frontend node pool
      frontend_node_vm_size       = "Standard_D2s_v5"
      frontend_node_initial_count = 1
      frontend_node_min_count     = 1
      frontend_node_max_count     = 5

      # Backend node pool
      backend_node_vm_size       = "Standard_D2s_v5"
      backend_node_initial_count = 1
      backend_node_min_count     = 1
      backend_node_max_count     = 5

      outbound_ip_count               = 2
      log_retention_days              = 30
      enable_app_gateway              = false
      create_acr                      = true
      acr_geo_replication_location    = "westus"
      api_server_authorized_ip_ranges = [] # Restrict to dev VPN/office IPs
      admin_group_object_ids          = [] # Add AAD group for dev admins

      tags = {
        Environment = "Development"
        ManagedBy   = "Terraform"
        Workspace   = "dev"
        CostCenter  = "Engineering"
      }
    }

    # ─────────────────────────────────────────────────────────────────────────
    # UAT / STAGING
    # ─────────────────────────────────────────────────────────────────────────
    uat = {
      resource_group_name = "aks-uat-rg"
      cluster_name        = "aks-uat-cluster"
      location            = "eastus"
      environment         = "uat"
      kubernetes_version  = "1.31"
      sku_tier            = "Standard"

      # System node pool
      system_node_vm_size   = "Standard_D4s_v5" # 4 vCPU / 16 GB
      system_node_count     = 3
      system_node_min_count = 3
      system_node_max_count = 6

      # Frontend node pool
      frontend_node_vm_size       = "Standard_D4s_v5"
      frontend_node_initial_count = 2
      frontend_node_min_count     = 2
      frontend_node_max_count     = 10

      # Backend node pool
      backend_node_vm_size       = "Standard_D4s_v5"
      backend_node_initial_count = 2
      backend_node_min_count     = 2
      backend_node_max_count     = 10

      outbound_ip_count               = 2
      log_retention_days              = 60
      enable_app_gateway              = false
      create_acr                      = true
      acr_geo_replication_location    = "westus"
      api_server_authorized_ip_ranges = [] # Restrict to UAT access IPs
      admin_group_object_ids          = [] # Add AAD group for UAT admins

      tags = {
        Environment = "UAT"
        ManagedBy   = "Terraform"
        Workspace   = "uat"
        CostCenter  = "Engineering"
      }
    }

    # ─────────────────────────────────────────────────────────────────────────
    # PRODUCTION
    # ─────────────────────────────────────────────────────────────────────────
    prod = {
      resource_group_name = "aks-prod-rg"
      cluster_name        = "aks-prod-cluster"
      location            = "eastus"
      environment         = "production"
      kubernetes_version  = "1.31"
      sku_tier            = "Premium" # 99.95% SLA on API server

      # System node pool
      system_node_vm_size   = "Standard_D4s_v5"
      system_node_count     = 3
      system_node_min_count = 3
      system_node_max_count = 6

      # Frontend node pool
      frontend_node_vm_size       = "Standard_D4s_v5"
      frontend_node_initial_count = 3
      frontend_node_min_count     = 3
      frontend_node_max_count     = 20

      # Backend node pool
      backend_node_vm_size       = "Standard_D4s_v5"
      backend_node_initial_count = 3
      backend_node_min_count     = 3
      backend_node_max_count     = 20

      outbound_ip_count               = 4
      log_retention_days              = 90
      enable_app_gateway              = false
      create_acr                      = true
      acr_geo_replication_location    = "westus"
      api_server_authorized_ip_ranges = [] # REQUIRED: add your office/VPN CIDRs
      admin_group_object_ids          = [] # REQUIRED: add your AAD admin group object ID

      tags = {
        Environment = "Production"
        ManagedBy   = "Terraform"
        Workspace   = "prod"
        CostCenter  = "Engineering"
      }
    }

  }

  # Active config for the current workspace
  config = local.env_config[terraform.workspace]
}
