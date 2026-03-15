# Frontend Node Pool - Optimized for serving web traffic
resource "azurerm_kubernetes_cluster_node_pool" "frontend" {
  name                  = "frontend"
  kubernetes_cluster_id = var.kubernetes_cluster_id
  vm_size               = var.frontend_node_vm_size
  node_count            = var.frontend_node_initial_count
  enable_auto_scaling   = true
  min_count             = var.frontend_node_min_count
  max_count             = var.frontend_node_max_count
  max_pods              = var.max_pods_per_node
  os_disk_size_gb       = 128
  os_disk_type          = "Managed"
  vnet_subnet_id        = var.aks_subnet_id
  zones                 = var.availability_zones

  node_labels = {
    "nodepool-type" = "frontend"
    "environment"   = var.environment
    "workload"      = "frontend"
    "app-tier"      = "presentation"
  }

  node_taints = []

  tags = merge(
    var.tags,
    {
      "nodepool" = "frontend"
      "tier"     = "presentation"
    }
  )
}

# Backend Node Pool - Optimized for API and business logic
resource "azurerm_kubernetes_cluster_node_pool" "backend" {
  name                  = "backend"
  kubernetes_cluster_id = var.kubernetes_cluster_id
  vm_size               = var.backend_node_vm_size
  node_count            = var.backend_node_initial_count
  enable_auto_scaling   = true
  min_count             = var.backend_node_min_count
  max_count             = var.backend_node_max_count
  max_pods              = var.max_pods_per_node
  os_disk_size_gb       = 256
  os_disk_type          = "Managed"
  vnet_subnet_id        = var.aks_subnet_id
  zones                 = var.availability_zones

  node_labels = {
    "nodepool-type" = "backend"
    "environment"   = var.environment
    "workload"      = "backend"
    "app-tier"      = "application"
  }

  node_taints = []

  tags = merge(
    var.tags,
    {
      "nodepool" = "backend"
      "tier"     = "application"
    }
  )
}
