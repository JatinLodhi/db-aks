output "identity_id" {
  description = "ID of the user assigned identity"
  value       = azurerm_user_assigned_identity.aks.id
}

output "principal_id" {
  description = "Principal ID of the user assigned identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "client_id" {
  description = "Client ID of the user assigned identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}
