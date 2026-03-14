variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "create_acr" {
  description = "Create Azure Container Registry"
  type        = bool
}

variable "acr_geo_replication_location" {
  description = "Location for ACR geo-replication"
  type        = string
}

variable "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
