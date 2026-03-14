# User Node Pool 1 - Primary workload pool with high capacity
resource "azurerm_kubernetes_cluster_node_pool" "user_pool_1" {
  name                  = "userpool1"
  kubernetes_cluster_id = var.kubernetes_cluster_id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_initial_count
  enable_auto_scaling   = true
  min_count             = var.user_node_min_count
  max_count             = var.user_node_max_count
  max_pods              = var.max_pods_per_node
  os_disk_size_gb       = 256
  os_disk_type          = "Managed"
  vnet_subnet_id        = var.aks_subnet_id
  zones                 = var.availability_zones

  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
    "workload"      = "general"
  }

  node_taints = []

  tags = merge(
    var.tags,
    {
      "nodepool" = "user-pool-1"
    }
  )
}

# User Node Pool 2 - Additional capacity for scaling
resource "azurerm_kubernetes_cluster_node_pool" "user_pool_2" {
  name                  = "userpool2"
  kubernetes_cluster_id = var.kubernetes_cluster_id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_initial_count
  enable_auto_scaling   = true
  min_count             = var.user_node_min_count
  max_count             = var.user_node_max_count
  max_pods              = var.max_pods_per_node
  os_disk_size_gb       = 256
  os_disk_type          = "Managed"
  vnet_subnet_id        = var.aks_subnet_id
  zones                 = var.availability_zones

  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
    "workload"      = "general"
  }

  node_taints = []

  tags = merge(
    var.tags,
    {
      "nodepool" = "user-pool-2"
    }
  )
}

# High-performance node pool for critical workloads (optional)
resource "azurerm_kubernetes_cluster_node_pool" "high_perf" {
  count                 = var.enable_high_perf_pool ? 1 : 0
  name                  = "highperf"
  kubernetes_cluster_id = var.kubernetes_cluster_id
  vm_size               = var.high_perf_node_vm_size
  node_count            = 3
  enable_auto_scaling   = true
  min_count             = 3
  max_count             = 20
  max_pods              = var.max_pods_per_node
  os_disk_size_gb       = 512
  os_disk_type          = "Managed"
  vnet_subnet_id        = var.aks_subnet_id
  zones                 = var.availability_zones

  node_labels = {
    "nodepool-type" = "high-performance"
    "environment"   = var.environment
    "workload"      = "critical"
  }

  node_taints = [
    "high-performance=true:NoSchedule"
  ]

  tags = merge(
    var.tags,
    {
      "nodepool" = "high-performance"
    }
  )
}
