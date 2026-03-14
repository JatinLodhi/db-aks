# Container Registry (optional but recommended)
resource "azurerm_container_registry" "acr" {
  count               = var.create_acr ? 1 : 0
  name                = replace("${var.cluster_name}acr", "-", "")
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium" # Premium for geo-replication and high throughput
  admin_enabled       = false

  georeplications {
    location                = var.acr_geo_replication_location
    zone_redundancy_enabled = true
    tags                    = var.tags
  }

  tags = var.tags
}

# Role assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.create_acr ? 1 : 0
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = var.kubelet_identity_object_id
}
