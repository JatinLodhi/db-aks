# GitHub Actions Deployment Setup

This guide explains how to set up and use GitHub Actions to deploy the AKS infrastructure.

## Overview

The GitHub Actions workflow automates Terraform deployment with three stages:
1. **Plan** - Validates and creates execution plan
2. **Manual Approval** - Requires manual approval before applying changes
3. **Apply** - Applies the approved changes to Azure

## Prerequisites

### 1. Azure Service Principal

Create a service principal with Contributor access:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-aks-deploy" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID> \
  --sdk-auth

# Output will look like:
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "...",
  ...
}
```

### 2. Azure Storage for Terraform State

Create storage account for remote state:

```bash
# Variables
RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="tfstateaks$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob \
  --location $LOCATION

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME

# Get storage account key
az storage account keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query '[0].value' -o tsv
```

## GitHub Repository Setup

### Required Secrets

Go to **Settings → Secrets and variables → Actions → Secrets**

Add the following **Repository Secrets**:

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `AZURE_CREDENTIALS` | Full JSON output from service principal creation | `{"clientId":"...","clientSecret":"..."}` |
| `ARM_CLIENT_ID` | Service Principal Client ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `ARM_CLIENT_SECRET` | Service Principal Client Secret | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `ARM_TENANT_ID` | Azure Tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `BACKEND_STORAGE_ACCESS_KEY` | Storage account access key for Terraform state | From step 2 above |
| `GITHUB_TOKEN` | GitHub Personal Access Token (for manual approval) | Generated from GitHub settings |

### Required Variables

Go to **Settings → Secrets and variables → Actions → Variables**

#### Environment Variables (per environment)

Create environments: `main` and `development`

For **main** environment:
| Variable Name | Value | Description |
|--------------|-------|-------------|
| `RESOURCE_GROUP_NAME` | `aks-prod-rg` | Production resource group |
| `CLUSTER_NAME` | `aks-prod-cluster` | Production cluster name |
| `LOCATION` | `eastus` | Azure region |
| `BACKEND_RESOURCE_GROUP` | `terraform-state-rg` | Backend resource group |
| `BACKEND_STORAGE_ACCOUNT` | `tfstateaksprod` | Backend storage account |
| `BACKEND_CONTAINER_NAME` | `tfstate` | Backend container |

For **development** environment:
| Variable Name | Value | Description |
|--------------|-------|-------------|
| `RESOURCE_GROUP_NAME` | `aks-dev-rg` | Development resource group |
| `CLUSTER_NAME` | `aks-dev-cluster` | Development cluster name |
| `LOCATION` | `eastus` | Azure region |
| `BACKEND_RESOURCE_GROUP` | `terraform-state-rg` | Backend resource group |
| `BACKEND_STORAGE_ACCOUNT` | `tfstateaksdev` | Backend storage account |
| `BACKEND_CONTAINER_NAME` | `tfstate` | Backend container |

## Environment Configuration Files

The workflow uses environment-specific `.tfvars` files located in `environments/`:

- `environments/main.tfvars` - Production configuration
- `environments/development.tfvars` - Development configuration
- `environments/backend-main.tfvars` - Production backend config
- `environments/backend-development.tfvars` - Development backend config

### Customizing Environment Files

Edit these files to customize your deployment:

```hcl
# environments/main.tfvars
resource_group_name = "aks-prod-rg"
cluster_name        = "aks-prod-cluster"
location            = "eastus"

frontend_node_vm_size       = "Standard_D4s_v5"
frontend_node_min_count     = 3
frontend_node_max_count     = 20

backend_node_vm_size        = "Standard_D4s_v5"
backend_node_min_count      = 3
backend_node_max_count      = 20

# ... more configuration
```

## Workflow Triggers

### Automatic Triggers

The workflow runs automatically on:
- Push to `main` branch (production)
- Push to `development` branch (development)
- Pull requests to `main` branch

### Manual Trigger

You can manually trigger the workflow:
1. Go to **Actions** tab
2. Select **Terraform AKS Deployment**
3. Click **Run workflow**
4. Choose the branch

## Deployment Process

### 1. Push Changes

```bash
git add .
git commit -m "Update AKS configuration"
git push origin main  # or development
```

### 2. Plan Stage

The workflow will:
- ✅ Check out code
- ✅ Login to Azure
- ✅ Initialize Terraform
- ✅ Validate configuration
- ✅ Create execution plan
- ✅ Upload plan artifact

### 3. Manual Approval

After the plan completes:
- 📋 A GitHub Issue will be created automatically
- 📧 Assigned approvers will be notified
- 👤 Approver: `jatinlodhi2002`

To approve:
1. Go to the **Issues** tab
2. Find the approval issue
3. Comment: `approve` or `yes`

To reject:
- Comment: `deny` or `no`

### 4. Apply Stage

Once approved:
- ✅ Downloads the approved plan
- ✅ Applies changes to Azure
- ✅ Retrieves AKS credentials
- ✅ Verifies deployment
- ✅ Posts summary

## Monitoring Deployment

### View Workflow Runs

1. Go to **Actions** tab
2. Click on the running workflow
3. View real-time logs for each job

### Check Terraform Plan

The plan output shows:
- Resources to be created (+)
- Resources to be modified (~)
- Resources to be destroyed (-)

### Deployment Status

After successful deployment, the workflow will show:
- Cluster status
- Node information
- Available namespaces

## Troubleshooting

### Failed Authentication

**Error:** `Error: building account: getting authenticated object ID`

**Solution:** Verify service principal credentials:
```bash
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID
```

### Backend Initialization Failed

**Error:** `Error: Failed to get existing workspaces`

**Solution:** Check storage account access:
```bash
az storage container list \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --account-key <ACCESS_KEY>
```

### Plan Generation Failed

**Error:** `Error: Invalid variable value`

**Solution:** Check environment tfvars file:
- Ensure all required variables are set
- Verify variable types match definitions

### Manual Approval Timeout

If the approval issue isn't created:
- Check `GITHUB_TOKEN` secret is set correctly
- Verify approver username is correct (case-sensitive)
- Check workflow permissions in repository settings

## Security Best Practices

1. **Never commit secrets** - Use GitHub Secrets
2. **Rotate credentials** regularly
3. **Use environment-specific** service principals
4. **Enable branch protection** on main branch
5. **Require pull request reviews** before merging
6. **Use least privilege access** for service principals
7. **Enable audit logs** in Azure
8. **Review Terraform plans** carefully before approval

## Local Testing

To test locally before pushing:

```bash
# Initialize with backend
terraform init \
  -var-file=environments/development.tfvars \
  -backend-config=environments/backend-development.tfvars \
  -backend-config="access_key=<YOUR_KEY>"

# Plan changes
terraform plan -var-file=environments/development.tfvars

# Apply (if needed)
terraform apply -var-file=environments/development.tfvars
```

## Cleanup

To destroy infrastructure:

```bash
# Via GitHub Actions
# 1. Comment out the apply step
# 2. Add: terraform destroy -auto-approve

# Or manually
terraform destroy -var-file=environments/main.tfvars
```

## Support

For issues or questions:
1. Check workflow logs in Actions tab
2. Review Terraform output
3. Check Azure Portal for resource status
4. Review this documentation

## Related Documentation

- [Terraform Configuration](./README.md)
- [Module Structure](./MODULE-STRUCTURE.md)
- [Frontend/Backend Architecture](./FRONTEND-BACKEND-ARCHITECTURE.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)
