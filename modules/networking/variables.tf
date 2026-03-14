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

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS nodes subnet"
  type        = string
}

variable "appgw_subnet_address_prefix" {
  description = "Address prefix for Application Gateway subnet"
  type        = string
}

variable "enable_app_gateway" {
  description = "Enable Application Gateway Ingress Controller"
  type        = bool
}

variable "availability_zones" {
  description = "Availability zones for resources"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
