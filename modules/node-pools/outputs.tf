output "frontend_pool_name" {
  description = "Name of frontend node pool"
  value       = azurerm_kubernetes_cluster_node_pool.frontend.name
}

output "backend_pool_name" {
  description = "Name of backend node pool"
  value       = azurerm_kubernetes_cluster_node_pool.backend.name
}
