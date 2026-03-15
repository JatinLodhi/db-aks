# Terraform Module Structure

This project has been restructured into a modular architecture for better organization and reusability.

## Module Structure

```
db-aks/
├── main.tf                          # Root module - orchestrates all submodules
├── variables.tf                     # Root module input variables
├── outputs.tf                       # Root module outputs (aggregated from submodules)
├── backend.tf                       # Backend configuration
├── terraform.tfvars.example         # Example variable values
│
├── modules/
│   ├── resource-group/              # Resource Group module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── networking/                  # Networking module (VNet, Subnets, Public IPs)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── identity/                    # Identity module (User Assigned Identity, Role Assignments)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── monitoring/                  # Monitoring module (Log Analytics)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── aks-cluster/                 # AKS Cluster module (main cluster with default node pool)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── node-pools/                  # Additional Node Pools module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── container-registry/          # Container Registry module (ACR)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── main.tf.backup                   # Backup of original monolithic main.tf
└── outputs.tf.backup                # Backup of original outputs.tf
```

## Modules Overview

### 1. Resource Group Module (`modules/resource-group`)
Creates the Azure Resource Group that contains all resources.

### 2. Networking Module (`modules/networking`)
- Virtual Network (VNet)
- AKS Nodes Subnet
- Application Gateway Subnet (optional)
- Application Gateway Public IP (optional)

### 3. Identity Module (`modules/identity`)
- User Assigned Identity for AKS
- Network Contributor role assignment for the identity

### 4. Monitoring Module (`modules/monitoring`)
- Log Analytics Workspace for monitoring and logging

### 5. AKS Cluster Module (`modules/aks-cluster`)
- AKS Cluster with default system node pool
- Network profile configuration
- Azure AD integration
- Auto-scaler profile
- Maintenance window
- API server access controls

### 6. Node Pools Module (`modules/node-pools`)
- User Node Pool 1 (primary workload pool)
- User Node Pool 2 (additional capacity)
- High-Performance Node Pool (optional, for critical workloads)

### 7. Container Registry Module (`modules/container-registry`)
- Azure Container Registry (ACR)
- ACR Pull role assignment for AKS
- Geo-replication configuration

## Usage

The module structure maintains the exact same functionality as before but with better organization:

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Plan deployment:**
   ```bash
   terraform plan
   ```

3. **Apply configuration:**
   ```bash
   terraform apply
   ```

## Benefits of Module Structure

1. **Separation of Concerns**: Each module handles a specific aspect of the infrastructure
2. **Reusability**: Modules can be reused across different projects
3. **Maintainability**: Easier to update and maintain individual components
4. **Testing**: Each module can be tested independently
5. **Clarity**: Clear dependencies between modules through input/output parameters
6. **Scalability**: Easy to add or remove modules as needed

## No Logic Changes

**Important**: This restructuring does NOT change any of the infrastructure code logic. All resources, configurations, and behaviors remain exactly the same as before. The only change is the organizational structure.

## Rollback

If needed, the original monolithic configuration is preserved in:
- `main.tf.backup`
- `outputs.tf.backup`

To rollback, simply restore these files to their original names.
