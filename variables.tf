variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "aks-high-scale-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-high-scale-cluster"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28" # Update to latest stable version
}

variable "sku_tier" {
  description = "SKU tier for AKS - Standard or Premium (Premium recommended for production)"
  type        = string
  default     = "Standard" # Use "Premium" for SLA and uptime guarantees
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/8" # Large address space for scaling
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS nodes subnet"
  type        = string
  default     = "10.240.0.0/12" # Large subnet for many pods
}

variable "appgw_subnet_address_prefix" {
  description = "Address prefix for Application Gateway subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service"
  type        = string
  default     = "10.2.0.10"
}

# System Node Pool Configuration
variable "system_node_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D4s_v5" # 4 vCPUs, 16GB RAM
}

variable "system_node_count" {
  description = "Initial number of nodes in system pool"
  type        = number
  default     = 3
}

variable "system_node_min_count" {
  description = "Minimum nodes in system pool"
  type        = number
  default     = 3
}

variable "system_node_max_count" {
  description = "Maximum nodes in system pool"
  type        = number
  default     = 6
}

# User Node Pool Configuration (for 100k concurrent users)
# Calculation: Assuming ~500 users per node with proper resource allocation
# 100k users / 500 = 200 nodes at peak
# With safety margin: min 50, max 250 nodes per pool
variable "user_node_vm_size" {
  description = "VM size for user node pools"
  type        = string
  default     = "Standard_D8s_v5" # 8 vCPUs, 32GB RAM - good for high concurrency
  # Alternative options:
  # Standard_D16s_v5 (16 vCPUs, 64GB) for more headroom
  # Standard_D32s_v5 (32 vCPUs, 128GB) for maximum capacity per node
}

variable "user_node_initial_count" {
  description = "Initial number of nodes in user pool"
  type        = number
  default     = 30 # Start with capacity for ~15k concurrent users
}

variable "user_node_min_count" {
  description = "Minimum nodes in user pool"
  type        = number
  default     = 20 # Maintain baseline for ~10k users
}

variable "user_node_max_count" {
  description = "Maximum nodes in user pool"
  type        = number
  default     = 150 # Scale up to handle ~75k users per pool (300 total with 2 pools)
}

# High Performance Node Pool (optional)
variable "enable_high_perf_pool" {
  description = "Enable high-performance node pool for critical workloads"
  type        = bool
  default     = true
}

variable "high_perf_node_vm_size" {
  description = "VM size for high-performance node pool"
  type        = string
  default     = "Standard_D16s_v5" # 16 vCPUs, 64GB RAM
}

# Pod Configuration
variable "max_pods_per_node" {
  description = "Maximum pods per node (Azure CNI limit: 250)"
  type        = number
  default     = 110 # Balance between density and resource availability
}

# Availability
variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = ["1", "2", "3"]
}

# Networking
variable "outbound_ip_count" {
  description = "Number of outbound IPs for load balancer (for high throughput)"
  type        = number
  default     = 4 # Multiple IPs to avoid SNAT port exhaustion
}

# Security
variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access"
  type        = list(string)
  default     = [] # Empty = public access. Restrict in production!
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admin access"
  type        = list(string)
  default     = [] # Add your Azure AD admin group IDs
}

# Monitoring
variable "log_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

# Application Gateway (optional)
variable "enable_app_gateway" {
  description = "Enable Application Gateway Ingress Controller"
  type        = bool
  default     = false # Set to true if you need WAF and advanced routing
}

# Container Registry
variable "create_acr" {
  description = "Create Azure Container Registry"
  type        = bool
  default     = true
}

variable "acr_geo_replication_location" {
  description = "Location for ACR geo-replication"
  type        = string
  default     = "westus"
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "High-Scale-AKS"
    CostCenter  = "Engineering"
  }
}
