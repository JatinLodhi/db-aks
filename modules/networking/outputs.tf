output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.aks.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.aks.name
}

output "aks_subnet_id" {
  description = "ID of the AKS nodes subnet"
  value       = azurerm_subnet.aks_nodes.id
}

output "appgw_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = var.enable_app_gateway ? azurerm_subnet.appgw[0].id : null
}

output "appgw_public_ip_id" {
  description = "ID of the Application Gateway public IP"
  value       = var.enable_app_gateway ? azurerm_public_ip.appgw[0].id : null
}
