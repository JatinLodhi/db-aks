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

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Module: Networking
module "networking" {
  source = "./modules/networking"

  cluster_name                = var.cluster_name
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  vnet_address_space          = var.vnet_address_space
  aks_subnet_address_prefix   = var.aks_subnet_address_prefix
  appgw_subnet_address_prefix = var.appgw_subnet_address_prefix
  enable_app_gateway          = var.enable_app_gateway
  availability_zones          = var.availability_zones
  tags                        = var.tags
}

# Module: Identity
module "identity" {
  source = "./modules/identity"

  cluster_name        = var.cluster_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  vnet_id             = module.networking.vnet_id
  tags                = var.tags
}

# Module: Monitoring
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name        = var.cluster_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  log_retention_days  = var.log_retention_days
  tags                = var.tags
}

# Module: AKS Cluster
module "aks_cluster" {
  source = "./modules/aks-cluster"

  cluster_name                    = var.cluster_name
  resource_group_name             = module.resource_group.name
  location                        = module.resource_group.location
  kubernetes_version              = var.kubernetes_version
  sku_tier                        = var.sku_tier
  environment                     = var.environment
  system_node_vm_size             = var.system_node_vm_size
  system_node_count               = var.system_node_count
  system_node_min_count           = var.system_node_min_count
  system_node_max_count           = var.system_node_max_count
  max_pods_per_node               = var.max_pods_per_node
  availability_zones              = var.availability_zones
  aks_subnet_id                   = module.networking.aks_subnet_id
  user_assigned_identity_id       = module.identity.identity_id
  service_cidr                    = var.service_cidr
  dns_service_ip                  = var.dns_service_ip
  outbound_ip_count               = var.outbound_ip_count
  log_analytics_workspace_id      = module.monitoring.workspace_id
  admin_group_object_ids          = var.admin_group_object_ids
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  tags                            = var.tags
  identity_depends_on             = module.identity.principal_id
}

# Module: Node Pools
module "node_pools" {
  source = "./modules/node-pools"

  kubernetes_cluster_id   = module.aks_cluster.cluster_id
  environment             = var.environment
  user_node_vm_size       = var.user_node_vm_size
  user_node_initial_count = var.user_node_initial_count
  user_node_min_count     = var.user_node_min_count
  user_node_max_count     = var.user_node_max_count
  max_pods_per_node       = var.max_pods_per_node
  aks_subnet_id           = module.networking.aks_subnet_id
  availability_zones      = var.availability_zones
  enable_high_perf_pool   = var.enable_high_perf_pool
  high_perf_node_vm_size  = var.high_perf_node_vm_size
  tags                    = var.tags
}

# Module: Container Registry
module "container_registry" {
  source = "./modules/container-registry"

  cluster_name                 = var.cluster_name
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  create_acr                   = var.create_acr
  acr_geo_replication_location = var.acr_geo_replication_location
  kubelet_identity_object_id   = module.aks_cluster.kubelet_identity_object_id
  tags                         = var.tags
}
