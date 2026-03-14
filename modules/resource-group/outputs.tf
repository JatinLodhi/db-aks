output "name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.aks.name
}

output "location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.aks.location
}

output "id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.aks.id
}
