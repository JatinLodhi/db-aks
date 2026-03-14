output "user_pool_1_name" {
  description = "Name of user node pool 1"
  value       = azurerm_kubernetes_cluster_node_pool.user_pool_1.name
}

output "user_pool_2_name" {
  description = "Name of user node pool 2"
  value       = azurerm_kubernetes_cluster_node_pool.user_pool_2.name
}

output "high_perf_pool_name" {
  description = "Name of high-performance node pool"
  value       = var.enable_high_perf_pool ? azurerm_kubernetes_cluster_node_pool.high_perf[0].name : null
}
