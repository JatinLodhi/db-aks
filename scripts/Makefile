.PHONY: help init plan apply destroy validate format clean deploy \
        workspace-dev workspace-uat workspace-prod workspace-show \
        get-credentials cluster-info nodes pods top-nodes top-pods \
        events logs-autoscaler hpa-status pdb-status \
        deploy-nginx deploy-cert-manager deploy-monitoring \
        acr-login load-test test backup-state outputs \
        upgrade-check security-scan start-cluster stop-cluster health-check

# Derived from Terraform outputs after deploy
CLUSTER_NAME   := $(shell terraform output -raw cluster_name 2>/dev/null)
RESOURCE_GROUP := $(shell terraform output -raw resource_group_name 2>/dev/null)
ACR_NAME       := $(shell terraform output -raw acr_name 2>/dev/null)
WORKSPACE      := $(shell terraform workspace show 2>/dev/null || echo "none")

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "  Active workspace: \033[33m$(WORKSPACE)\033[0m"

# ─── Workspace Management ────────────────────────────────────────────────────

workspace-dev: ## Switch to dev workspace
	terraform workspace select dev 2>/dev/null || terraform workspace new dev
	@echo "Active workspace: $$(terraform workspace show)"

workspace-uat: ## Switch to uat workspace
	terraform workspace select uat 2>/dev/null || terraform workspace new uat
	@echo "Active workspace: $$(terraform workspace show)"

workspace-prod: ## Switch to prod workspace
	terraform workspace select prod 2>/dev/null || terraform workspace new prod
	@echo "Active workspace: $$(terraform workspace show)"

workspace-show: ## Show current workspace
	@terraform workspace show
	@echo ""
	@terraform workspace list

# ─── Terraform Core ──────────────────────────────────────────────────────────

init: ## Initialise Terraform (run once or after provider changes)
	@echo "Initialising Terraform..."
	terraform init

validate: ## Validate configuration
	terraform validate

format: ## Format all Terraform files in-place
	terraform fmt -recursive

plan: ## Plan for active workspace (no var-file needed)
	@echo "Planning for workspace: $(WORKSPACE)"
	terraform plan -out=tfplan-$(WORKSPACE)

apply: ## Apply saved plan for active workspace
	@echo "Applying plan for workspace: $(WORKSPACE)"
	@read -p "Apply changes to [$(WORKSPACE)]? [y/N] " -n 1 -r; echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		terraform apply tfplan-$(WORKSPACE); \
	else \
		echo "Cancelled."; \
	fi

destroy: ## Destroy all resources in active workspace (DANGEROUS)
	@echo "WARNING: This will destroy all resources in workspace [$(WORKSPACE)]!"
	@read -p "Type the workspace name to confirm: " confirm; \
	if [ "$$confirm" = "$(WORKSPACE)" ]; then \
		terraform destroy; \
	else \
		echo "Cancelled."; \
	fi

deploy: init validate plan apply get-credentials ## Full deployment for active workspace
	@echo "Deployment complete for workspace: $(WORKSPACE)"

clean: ## Remove local plan files and .terraform cache
	rm -f tfplan-*
	rm -f crash.log
	rm -rf .terraform/

outputs: ## Show Terraform outputs for active workspace
	terraform output

# ─── Cluster Access ──────────────────────────────────────────────────────────

get-credentials: ## Fetch kubeconfig for the active workspace cluster
	@if [ -z "$(CLUSTER_NAME)" ] || [ -z "$(RESOURCE_GROUP)" ]; then \
		echo "Error: cluster not deployed yet (no outputs)"; exit 1; \
	fi
	az aks get-credentials --resource-group $(RESOURCE_GROUP) --name $(CLUSTER_NAME) --overwrite-existing

# ─── Cluster Inspection ──────────────────────────────────────────────────────

cluster-info: ## Show cluster info
	@echo "Workspace:      $(WORKSPACE)"
	@echo "Cluster:        $(CLUSTER_NAME)"
	@echo "Resource Group: $(RESOURCE_GROUP)"
	@echo "ACR:            $(ACR_NAME)"
	@kubectl cluster-info 2>/dev/null || echo "Not connected to cluster"

nodes: ## List nodes with details
	kubectl get nodes -o wide

pods: ## List all pods across all namespaces
	kubectl get pods -A -o wide

top-nodes: ## Node resource usage
	kubectl top nodes

top-pods: ## Pod resource usage
	kubectl top pods -A

events: ## Recent cluster events (last 50)
	kubectl get events -A --sort-by='.lastTimestamp' | tail -n 50

logs-autoscaler: ## Cluster autoscaler logs
	kubectl logs -n kube-system -l app=cluster-autoscaler --tail=100

hpa-status: ## HPA status
	kubectl get hpa -A

pdb-status: ## Pod Disruption Budget status
	kubectl get pdb -A

health-check: ## Comprehensive node/pod/event health check
	@echo "=== Cluster Health Check (workspace: $(WORKSPACE)) ==="
	@kubectl get nodes -o wide
	@echo ""
	@echo "--- Failed Pods ---"
	@kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded \
	  | grep -v "Completed" || echo "None"
	@echo ""
	@echo "--- Node Resource Usage ---"
	@kubectl top nodes 2>/dev/null || echo "Metrics server not available"
	@echo ""
	@echo "--- Recent Events (last 20) ---"
	@kubectl get events -A --sort-by='.lastTimestamp' | tail -n 20

# ─── Scaling ─────────────────────────────────────────────────────────────────

scale-nodes: ## Manually scale a node pool
	@az aks nodepool list --resource-group $(RESOURCE_GROUP) --cluster-name $(CLUSTER_NAME) -o table
	@read -p "Node pool name: " pool; \
	read -p "Desired node count: " count; \
	az aks nodepool scale --resource-group $(RESOURCE_GROUP) \
	  --cluster-name $(CLUSTER_NAME) --name $$pool --node-count $$count

# ─── Add-ons ─────────────────────────────────────────────────────────────────

deploy-nginx: ## Install NGINX Ingress Controller via Helm
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update
	helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--create-namespace \
		--set controller.replicaCount=3 \
		--set controller.resources.requests.cpu=100m \
		--set controller.resources.requests.memory=128Mi

deploy-cert-manager: ## Install cert-manager
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

deploy-monitoring: ## Install Prometheus + Grafana via Helm
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
		--namespace monitoring \
		--create-namespace \
		--set prometheus.prometheusSpec.retention=30d

# ─── ACR ─────────────────────────────────────────────────────────────────────

acr-login: ## Login to ACR for the active workspace
	@if [ -z "$(ACR_NAME)" ]; then echo "Error: ACR not deployed"; exit 1; fi
	az acr login --name $(ACR_NAME)

# ─── Maintenance ─────────────────────────────────────────────────────────────

backup-state: ## Backup Terraform state for active workspace
	mkdir -p backups
	terraform state pull > backups/$(WORKSPACE)-$(shell date +%Y%m%d-%H%M%S).tfstate
	@echo "State backed up to backups/"

upgrade-check: ## Check available Kubernetes version upgrades
	az aks get-upgrades --resource-group $(RESOURCE_GROUP) --name $(CLUSTER_NAME) -o table

security-scan: ## Run Checkov + TFSec scans
	@checkov -d .. --framework terraform || echo "Install: pip install checkov"
	@tfsec .. || echo "Install: https://github.com/aquasecurity/tfsec"

start-cluster: ## Start a stopped AKS cluster
	az aks start --resource-group $(RESOURCE_GROUP) --name $(CLUSTER_NAME)

stop-cluster: ## Stop AKS cluster to save cost
	@read -p "Stop cluster [$(CLUSTER_NAME)] in workspace [$(WORKSPACE)]? Type 'yes': " c; \
	if [ "$$c" = "yes" ]; then \
		az aks stop --resource-group $(RESOURCE_GROUP) --name $(CLUSTER_NAME); \
	fi

test: ## Basic cluster connectivity tests
	kubectl cluster-info
	kubectl get nodes
	kubectl get pods -n kube-system
	kubectl get pdb -A
