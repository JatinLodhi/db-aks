# Environment: Development
# This file contains development-specific configuration

# Basic Configuration
resource_group_name = "aks-dev-rg"
cluster_name        = "aks-dev-cluster"
location            = "eastus"
environment         = "development"

# Kubernetes Configuration
kubernetes_version = "1.28"
sku_tier           = "Standard" # Use Standard for dev, Premium for production

# Network Configuration
vnet_address_space          = "10.0.0.0/8"
aks_subnet_address_prefix   = "10.240.0.0/12"
appgw_subnet_address_prefix = "10.1.0.0/24"
service_cidr                = "10.2.0.0/16"
dns_service_ip              = "10.2.0.10"

# System Node Pool
system_node_vm_size   = "Standard_D4s_v5"
system_node_count     = 3
system_node_min_count = 3
system_node_max_count = 5

# Frontend Node Pool
frontend_node_vm_size       = "Standard_D4s_v5"
frontend_node_initial_count = 2
frontend_node_min_count     = 2
frontend_node_max_count     = 10

# Backend Node Pool
backend_node_vm_size       = "Standard_D4s_v5"
backend_node_initial_count = 2
backend_node_min_count     = 2
backend_node_max_count     = 10

# Resource Configuration
max_pods_per_node  = 110
availability_zones = ["1", "2", "3"]
outbound_ip_count  = 2
log_retention_days = 30

# Features
enable_app_gateway = false
create_acr         = true

# ACR Configuration
acr_geo_replication_location = "westus"

# Security
api_server_authorized_ip_ranges = [] # Add your IP ranges for production
admin_group_object_ids          = [] # Add Azure AD group IDs

# Tags
tags = {
  Environment = "Development"
  ManagedBy   = "Terraform"
  Purpose     = "AKS-Development"
  CostCenter  = "Engineering"
  Project     = "Frontend-Backend-App"
}
