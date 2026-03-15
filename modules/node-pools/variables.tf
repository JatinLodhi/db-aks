variable "kubernetes_cluster_id" {
  description = "ID of the AKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Frontend Node Pool Configuration
variable "frontend_node_vm_size" {
  description = "VM size for frontend node pool"
  type        = string
}

variable "frontend_node_initial_count" {
  description = "Initial number of nodes in frontend pool"
  type        = number
}

variable "frontend_node_min_count" {
  description = "Minimum nodes in frontend pool"
  type        = number
}

variable "frontend_node_max_count" {
  description = "Maximum nodes in frontend pool"
  type        = number
}

# Backend Node Pool Configuration
variable "backend_node_vm_size" {
  description = "VM size for backend node pool"
  type        = string
}

variable "backend_node_initial_count" {
  description = "Initial number of nodes in backend pool"
  type        = number
}

variable "backend_node_min_count" {
  description = "Minimum nodes in backend pool"
  type        = number
}

variable "backend_node_max_count" {
  description = "Maximum nodes in backend pool"
  type        = number
}

variable "max_pods_per_node" {
  description = "Maximum pods per node"
  type        = number
}

variable "aks_subnet_id" {
  description = "ID of the AKS nodes subnet"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
