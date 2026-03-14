variable "kubernetes_cluster_id" {
  description = "ID of the AKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "user_node_vm_size" {
  description = "VM size for user node pools"
  type        = string
}

variable "user_node_initial_count" {
  description = "Initial number of nodes in user pool"
  type        = number
}

variable "user_node_min_count" {
  description = "Minimum nodes in user pool"
  type        = number
}

variable "user_node_max_count" {
  description = "Maximum nodes in user pool"
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

variable "enable_high_perf_pool" {
  description = "Enable high-performance node pool for critical workloads"
  type        = bool
}

variable "high_perf_node_vm_size" {
  description = "VM size for high-performance node pool"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
