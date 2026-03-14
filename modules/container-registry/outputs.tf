output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = var.create_acr ? azurerm_container_registry.acr[0].id : null
}

output "acr_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = var.create_acr ? azurerm_container_registry.acr[0].login_server : null
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = var.create_acr ? azurerm_container_registry.acr[0].name : null
}
