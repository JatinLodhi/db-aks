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

# Frontend Node Pool Configuration
variable "frontend_node_vm_size" {
  description = "VM size for frontend node pool (optimized for serving web traffic)"
  type        = string
  default     = "Standard_D4s_v5" # 4 vCPUs, 16GB RAM - suitable for frontend workloads
  # Alternative options:
  # Standard_D2s_v5 (2 vCPUs, 8GB) for lighter frontend
  # Standard_D8s_v5 (8 vCPUs, 32GB) for heavier frontend traffic
}

variable "frontend_node_initial_count" {
  description = "Initial number of nodes in frontend pool"
  type        = number
  default     = 3 # Start with 3 nodes for availability
}

variable "frontend_node_min_count" {
  description = "Minimum nodes in frontend pool"
  type        = number
  default     = 3 # Maintain at least 3 nodes across zones
}

variable "frontend_node_max_count" {
  description = "Maximum nodes in frontend pool"
  type        = number
  default     = 20 # Scale up for high traffic
}

# Backend Node Pool Configuration
variable "backend_node_vm_size" {
  description = "VM size for backend node pool (optimized for API and business logic)"
  type        = string
  default     = "Standard_D4s_v5" # 4 vCPUs, 16GB RAM - good for backend processing
  # Alternative options:
  # Standard_D8s_v5 (8 vCPUs, 32GB) for heavier backend load
  # Standard_D16s_v5 (16 vCPUs, 64GB) for intensive backend processing
}

variable "backend_node_initial_count" {
  description = "Initial number of nodes in backend pool"
  type        = number
  default     = 3 # Start with 3 nodes for availability
}

variable "backend_node_min_count" {
  description = "Minimum nodes in backend pool"
  type        = number
  default     = 3 # Maintain at least 3 nodes for availability
}

variable "backend_node_max_count" {
  description = "Maximum nodes in backend pool"
  type        = number
  default     = 20 # Scale up for high traffic
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
