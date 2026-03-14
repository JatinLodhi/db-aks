output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks_cluster.cluster_name
}

output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks_cluster.cluster_id
}

output "kube_config" {
  description = "Kubeconfig for the AKS cluster"
  value       = module.aks_cluster.kube_config_raw
  sensitive   = true
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks_cluster.cluster_fqdn
}

output "cluster_endpoint" {
  description = "Endpoint for the AKS cluster API server"
  value       = module.aks_cluster.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "CA certificate for the AKS cluster"
  value       = module.aks_cluster.cluster_ca_certificate
  sensitive   = true
}

output "node_resource_group" {
  description = "Auto-generated resource group for AKS nodes"
  value       = module.aks_cluster.node_resource_group
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity"
  value       = module.aks_cluster.kubelet_identity_object_id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the kubelet identity"
  value       = module.aks_cluster.kubelet_identity_client_id
}

output "aks_identity_principal_id" {
  description = "Principal ID of the AKS cluster identity"
  value       = module.identity.principal_id
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "aks_subnet_id" {
  description = "ID of the AKS nodes subnet"
  value       = module.networking.aks_subnet_id
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = module.monitoring.workspace_name
}

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = module.container_registry.acr_id
}

output "acr_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = module.container_registry.acr_login_server
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.container_registry.acr_name
}

output "system_node_pool_name" {
  description = "Name of the system node pool"
  value       = module.aks_cluster.system_node_pool_name
}

output "user_pool_1_name" {
  description = "Name of user node pool 1"
  value       = module.node_pools.user_pool_1_name
}

output "user_pool_2_name" {
  description = "Name of user node pool 2"
  value       = module.node_pools.user_pool_2_name
}

output "high_perf_pool_name" {
  description = "Name of high-performance node pool"
  value       = module.node_pools.high_perf_pool_name
}

output "total_max_nodes" {
  description = "Maximum total nodes across all pools"
  value       = var.system_node_max_count + (var.user_node_max_count * 2) + (var.enable_high_perf_pool ? 20 : 0)
}

output "estimated_max_concurrent_users" {
  description = "Estimated maximum concurrent users (rough calculation)"
  value       = (var.user_node_max_count * 2 * 500) + (var.enable_high_perf_pool ? 10000 : 0)
}

# Commands for quick access
output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks_cluster.cluster_name}"
}

output "connect_to_acr_command" {
  description = "Command to login to ACR"
  value       = var.create_acr ? "az acr login --name ${module.container_registry.acr_name}" : null
}
