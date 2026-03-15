# Environment: Production
# This file contains production-specific configuration

# Basic Configuration
resource_group_name = "aks-prod-rg"
cluster_name        = "aks-prod-cluster"
location            = "eastus"
environment         = "production"

# Kubernetes Configuration
kubernetes_version = "1.28"
sku_tier           = "Standard" # Use Premium for SLA and uptime guarantees

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
system_node_max_count = 6

# Frontend Node Pool
frontend_node_vm_size       = "Standard_D4s_v5"
frontend_node_initial_count = 3
frontend_node_min_count     = 3
frontend_node_max_count     = 20

# Backend Node Pool
backend_node_vm_size       = "Standard_D4s_v5"
backend_node_initial_count = 3
backend_node_min_count     = 3
backend_node_max_count     = 20

# Resource Configuration
max_pods_per_node  = 110
availability_zones = ["1", "2", "3"]
outbound_ip_count  = 4
log_retention_days = 90

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
  Environment = "Production"
  ManagedBy   = "Terraform"
  Purpose     = "AKS-Production"
  CostCenter  = "Engineering"
  Project     = "Frontend-Backend-App"
}
