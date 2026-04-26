terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Module: Resource Group
module "resource_group" {
  source = "./modules/resource-group"

  resource_group_name = local.config.resource_group_name
  location            = local.config.location
  tags                = local.config.tags
}

# Module: Networking
module "networking" {
  source = "./modules/networking"

  cluster_name                = local.config.cluster_name
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  vnet_address_space          = var.vnet_address_space
  aks_subnet_address_prefix   = var.aks_subnet_address_prefix
  appgw_subnet_address_prefix = var.appgw_subnet_address_prefix
  enable_app_gateway          = local.config.enable_app_gateway
  availability_zones          = var.availability_zones
  tags                        = local.config.tags
}

# Module: Identity
module "identity" {
  source = "./modules/identity"

  cluster_name        = local.config.cluster_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  vnet_id             = module.networking.vnet_id
  tags                = local.config.tags
}

# Module: Monitoring
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name        = local.config.cluster_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  log_retention_days  = local.config.log_retention_days
  tags                = local.config.tags
}

# Module: AKS Cluster
module "aks_cluster" {
  source = "./modules/aks-cluster"

  cluster_name                    = local.config.cluster_name
  resource_group_name             = module.resource_group.name
  location                        = module.resource_group.location
  kubernetes_version              = local.config.kubernetes_version
  sku_tier                        = local.config.sku_tier
  environment                     = local.config.environment
  system_node_vm_size             = local.config.system_node_vm_size
  system_node_count               = local.config.system_node_count
  system_node_min_count           = local.config.system_node_min_count
  system_node_max_count           = local.config.system_node_max_count
  max_pods_per_node               = var.max_pods_per_node
  availability_zones              = var.availability_zones
  aks_subnet_id                   = module.networking.aks_subnet_id
  user_assigned_identity_id       = module.identity.identity_id
  service_cidr                    = var.service_cidr
  dns_service_ip                  = var.dns_service_ip
  outbound_ip_count               = local.config.outbound_ip_count
  log_analytics_workspace_id      = module.monitoring.workspace_id
  admin_group_object_ids          = local.config.admin_group_object_ids
  api_server_authorized_ip_ranges = local.config.api_server_authorized_ip_ranges
  tags                            = local.config.tags
  identity_depends_on             = module.identity.principal_id
}

# Module: Node Pools
module "node_pools" {
  source = "./modules/node-pools"

  kubernetes_cluster_id       = module.aks_cluster.cluster_id
  environment                 = local.config.environment
  frontend_node_vm_size       = local.config.frontend_node_vm_size
  frontend_node_initial_count = local.config.frontend_node_initial_count
  frontend_node_min_count     = local.config.frontend_node_min_count
  frontend_node_max_count     = local.config.frontend_node_max_count
  backend_node_vm_size        = local.config.backend_node_vm_size
  backend_node_initial_count  = local.config.backend_node_initial_count
  backend_node_min_count      = local.config.backend_node_min_count
  backend_node_max_count      = local.config.backend_node_max_count
  max_pods_per_node           = var.max_pods_per_node
  aks_subnet_id               = module.networking.aks_subnet_id
  availability_zones          = var.availability_zones
  tags                        = local.config.tags
}

# Module: Container Registry
module "container_registry" {
  source = "./modules/container-registry"

  cluster_name                 = local.config.cluster_name
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  create_acr                   = local.config.create_acr
  acr_geo_replication_location = local.config.acr_geo_replication_location
  kubelet_identity_object_id   = module.aks_cluster.kubelet_identity_object_id
  tags                         = local.config.tags
}
