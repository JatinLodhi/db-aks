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

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "sku_tier" {
  description = "SKU tier for AKS - Standard or Premium"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "system_node_vm_size" {
  description = "VM size for system node pool"
  type        = string
}

variable "system_node_count" {
  description = "Initial number of nodes in system pool"
  type        = number
}

variable "system_node_min_count" {
  description = "Minimum nodes in system pool"
  type        = number
}

variable "system_node_max_count" {
  description = "Maximum nodes in system pool"
  type        = number
}

variable "max_pods_per_node" {
  description = "Maximum pods per node"
  type        = number
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
}

variable "aks_subnet_id" {
  description = "ID of the AKS nodes subnet"
  type        = string
}

variable "user_assigned_identity_id" {
  description = "ID of the user assigned identity"
  type        = string
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service"
  type        = string
}

variable "outbound_ip_count" {
  description = "Number of outbound IPs for load balancer"
  type        = number
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admin access"
  type        = list(string)
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "identity_depends_on" {
  description = "Dependency on identity role assignment"
  type        = any
  default     = null
}
