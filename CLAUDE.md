# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

Terraform infrastructure for a production-grade Azure Kubernetes Service (AKS) cluster designed for high-scale workloads (100k+ concurrent users). It uses Terraform workspaces to fully separate environments — switching workspace changes every environment-specific value automatically with no var-files required.

## Workspace-Based Environment Model

All environment-specific config lives in `workspace_config.tf` as a locals map. Three workspaces are defined: `dev`, `uat`, `prod`. Active workspace config is accessed as `local.config.<key>` throughout `main.tf` and `outputs.tf`.

```
terraform workspace → local.config → all modules
```

**`variables.tf`** only holds shared network CIDRs and availability zones (same across all environments). Do not add environment-specific values there — they belong in `workspace_config.tf`.

## Common Commands

**Select environment first, then plan/apply:**
```bash
terraform workspace select dev     # or uat / prod
terraform workspace new dev        # first time only
terraform workspace show           # confirm active workspace
```

**Deploy workflow:**
```bash
terraform init                     # first-time or after provider changes
terraform validate
terraform plan -out=tfplan-dev     # no -var-file needed
terraform apply tfplan-dev
terraform output                   # verify
```

**Makefile shortcuts (run from `scripts/` directory):**
```bash
make workspace-dev     # switch to dev
make workspace-uat     # switch to uat
make workspace-prod    # switch to prod
make plan              # plan for active workspace
make apply             # apply for active workspace (prompts confirmation)
make deploy            # init + validate + plan + apply + get-credentials
make health-check      # kubectl nodes/pods/events
make upgrade-check     # available K8s upgrades
make security-scan     # Checkov + TFSec
make stop-cluster      # stop cluster to save cost
make deploy-nginx      # NGINX Ingress via Helm
make deploy-monitoring # Prometheus + Grafana via Helm
```

**Post-deploy cluster access:**
```bash
az aks get-credentials --resource-group aks-dev-rg --name aks-dev-cluster
# or: make get-credentials
```

## Backend (Remote State)

`backend.tf` is enabled with the azurerm backend. Workspaces automatically isolate state:
- `dev`  → `aks.tfstate/dev/terraform.tfstate`
- `uat`  → `aks.tfstate/uat/terraform.tfstate`
- `prod` → `aks.tfstate/prod/terraform.tfstate`

One-time setup before first `terraform init`:
```bash
az group create --name terraform-state-rg --location eastus
az storage account create --name tfstateaks<suffix> \
  --resource-group terraform-state-rg --sku Standard_LRS
az storage container create --name tfstate --account-name tfstateaks<suffix>
```
Then update `storage_account_name` in `backend.tf`.

For **local backend** (no Azure storage), comment out the `backend "azurerm"` block in `backend.tf`. State will be stored in `terraform.tfstate.d/<workspace>/terraform.tfstate`.

## Architecture

### Module Dependency Chain

```
resource-group
    └── networking (VNet, AKS subnet, optional AppGW subnet/IP)
    └── identity   (User Assigned Identity + Network Contributor on VNet)
    └── monitoring (Log Analytics workspace)
            └── aks-cluster (system pool, autoscaler, AAD RBAC, OMS agent)
                    └── node-pools (frontend + backend additional pools)
                    └── container-registry (ACR Premium + AcrPull to kubelet identity)
```

`main.tf` at the root is the sole orchestration layer — it calls all 7 modules and pipes outputs between them.

### Node Pool Design

| Pool | Dev VM / Min–Max | UAT VM / Min–Max | Prod VM / Min–Max | OS Disk | Labels |
|---|---|---|---|---|---|
| `system` | D2s_v5 / 2–4 | D4s_v5 / 3–6 | D4s_v5 / 3–6 | 128 GB | nodepool-type=system |
| `frontend` | D2s_v5 / 1–5 | D4s_v5 / 2–10 | D4s_v5 / 3–20 | 128 GB | workload=frontend |
| `backend` | D2s_v5 / 1–5 | D4s_v5 / 2–10 | D4s_v5 / 3–20 | 256 GB | workload=backend |

All pools span availability zones 1–2–3. Max 110 pods/node (Azure CNI). Node labels are set but **taints are currently empty** — add taints in `workspace_config.tf` if you want hard workload isolation.

### Networking (Shared Across Workspaces)

- **Plugin**: Azure CNI — pods get VNet IPs directly
- **VNet**: `10.0.0.0/8` → AKS subnet `10.240.0.0/12`
- **Services**: `10.2.0.0/16`, DNS at `10.2.0.10`
- **Outbound**: Standard LB — 2 managed IPs (dev/uat), 4 managed IPs (prod)
- **App Gateway**: subnet and public IP created when `enable_app_gateway = true`; defaults to `false` — no ingress controller is provisioned by Terraform

### Identity & ACR

AKS uses a **User Assigned Identity** (not system-assigned). The auto-created kubelet identity gets `AcrPull` on the ACR (in `container-registry` module). The cluster identity gets `Network Contributor` on the VNet (in `identity` module).

### CI/CD (GitHub Actions)

Branch → workspace mapping:
- `main` → `prod`
- `uat` → `uat`
- `dev` → `dev`

Flow: push triggers `terraform-plan` → manual approval gate (approver: `jatinlodhi2002`) → `terraform-apply`. No `-var-file` is used — workspace selection handles everything. Terraform version: `1.10.0`.

## Adding a New Environment

1. Add a new key (e.g., `staging`) to `local.env_config` in `workspace_config.tf` following the existing pattern
2. Run `terraform workspace new staging && terraform plan`
3. Add the branch to `.github/workflows/terraform.yml` triggers and the `resolve workspace` case statements

## Known Gaps to Address

- **`api_server_authorized_ip_ranges = []`** in all envs in `workspace_config.tf` — API server is publicly accessible. Add office/VPN CIDRs.
- **`admin_group_object_ids = []`** in all envs — AAD RBAC is enabled but no admin group is assigned.
- **No ingress controller** provisioned by Terraform — run `make deploy-nginx` post-deploy.
- **Node taints are empty** — without taints, pods are not forced to their intended pool.
- **`only_critical_addons_enabled`** is not set on the system pool — user workloads can land on system nodes.
