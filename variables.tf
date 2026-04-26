# Shared network variables — identical across all workspaces.
# Environment-specific values (cluster name, node sizes, counts, tags, etc.)
# are defined in workspace_config.tf and referenced as local.config.<key>.

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/8"
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS nodes subnet"
  type        = string
  default     = "10.240.0.0/12"
}

variable "appgw_subnet_address_prefix" {
  description = "Address prefix for Application Gateway subnet (only used when enable_app_gateway = true)"
  type        = string
  default     = "10.1.0.0/24"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service (must be within service_cidr)"
  type        = string
  default     = "10.2.0.10"
}

variable "max_pods_per_node" {
  description = "Maximum pods per node — Azure CNI supports up to 250"
  type        = number
  default     = 110
}

variable "availability_zones" {
  description = "Availability zones for all node pools"
  type        = list(string)
  default     = ["1", "2", "3"]
}
