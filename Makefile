.PHONY: help init plan apply destroy validate format clean cost-estimate deploy test

# Variables
CLUSTER_NAME := $(shell terraform output -raw cluster_name 2>/dev/null)
RESOURCE_GROUP := $(shell terraform output -raw resource_group_name 2>/dev/null)
ACR_NAME := $(shell terraform output -raw acr_name 2>/dev/null)

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	@echo "Initializing Terraform..."
	terraform init

validate: ## Validate Terraform configuration
	@echo "Validating Terraform configuration..."
	terraform validate

format: ## Format Terraform files
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

plan: ## Create Terraform plan
	@echo "Creating Terraform plan..."
	terraform plan -out=tfplan

apply: ## Apply Terraform changes
	@echo "Applying Terraform changes..."
	@read -p "Are you sure you want to apply changes? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		terraform apply tfplan; \
	else \
		echo "Apply cancelled."; \
	fi

destroy: ## Destroy all resources (DANGEROUS!)
	@echo "WARNING: This will destroy all resources!"
	@read -p "Type 'yes' to confirm destruction: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		terraform destroy; \
	else \
		echo "Destroy cancelled."; \
	fi

clean: ## Clean up temporary files
	@echo "Cleaning up temporary files..."
	rm -f tfplan
	rm -f *.tfstate*
	rm -f crash.log
	rm -rf .terraform/

cost-estimate: ## Estimate infrastructure costs
	@echo "Running cost estimation..."
	./cost-calculator.sh

deploy: init validate plan apply get-credentials ## Full deployment workflow
	@echo "Deployment complete!"

get-credentials: ## Get AKS credentials
	@echo "Getting AKS credentials..."
	@if [ -z "$(CLUSTER_NAME)" ] || [ -z "$(RESOURCE_GROUP)" ]; then \
		echo "Error: Cluster not deployed yet"; \
		exit 1; \
	fi
	az aks get-credentials --resource-group $(RESOURCE_GROUP) --name $(CLUSTER_NAME) --overwrite-existing

cluster-info: ## Show cluster information
	@echo "Cluster Information:"
	@echo "  Name: $(CLUSTER_NAME)"
	@echo "  Resource Group: $(RESOURCE_GROUP)"
	@echo "  ACR: $(ACR_NAME)"
	@echo ""
	@kubectl cluster-info 2>/dev/null || echo "Not connected to cluster"

nodes: ## Show cluster nodes
	@kubectl get nodes -o wide

pods: ## Show all pods
	@kubectl get pods -A -o wide

top-nodes: ## Show node resource usage
	@kubectl top nodes

top-pods: ## Show pod resource usage
	@kubectl top pods -A

scale-nodes: ## Manually scale node pool
	@echo "Current node pools:"
	@az aks nodepool list --resource-group $(RESOURCE_GROUP) --cluster-name $(CLUSTER_NAME) -o table
	@read -p "Enter node pool name: " pool; \
	read -p "Enter desired node count: " count; \
	az aks nodepool scale --resource-group $(RESOURCE_GROUP) --cluster-name $(CLUSTER_NAME) --name $$pool --node-count $$count

events: ## Show cluster events
	@kubectl get events -A --sort-by='.lastTimestamp' | tail -n 50

logs-autoscaler: ## Show cluster autoscaler logs
	@kubectl logs -n kube-system -l app=cluster-autoscaler --tail=100

hpa-status: ## Show HPA status
	@kubectl get hpa -A

pdb-status: ## Show Pod Disruption Budget status
	@kubectl get pdb -A

deploy-nginx: ## Deploy NGINX Ingress Controller
	@echo "Installing NGINX Ingress Controller..."
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update
	helm install ingress-nginx ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--create-namespace \
		--set controller.replicaCount=3 \
		--set controller.resources.requests.cpu=100m \
		--set controller.resources.requests.memory=128Mi

deploy-cert-manager: ## Deploy cert-manager
	@echo "Installing cert-manager..."
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

deploy-monitoring: ## Deploy Prometheus + Grafana
	@echo "Installing Prometheus and Grafana..."
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm install prometheus prometheus-community/kube-prometheus-stack \
		--namespace monitoring \
		--create-namespace \
		--set prometheus.prometheusSpec.retention=30d

acr-login: ## Login to Azure Container Registry
	@if [ -z "$(ACR_NAME)" ]; then \
		echo "Error: ACR not deployed"; \
		exit 1; \
	fi
	az acr login --name $(ACR_NAME)

load-test: ## Run load test
	@echo "Running load test..."
	@if [ ! -f "load-test.js" ]; then \
		echo "Error: load-test.js not found"; \
		exit 1; \
	fi
	@read -p "Enter target URL (e.g., https://your-app.com): " url; \
	BASE_URL=$$url k6 run load-test.js

test: ## Run basic cluster tests
	@echo "Running cluster tests..."
	@echo "Testing API server connectivity..."
	@kubectl cluster-info
	@echo ""
	@echo "Checking node health..."
	@kubectl get nodes
	@echo ""
	@echo "Checking system pods..."
	@kubectl get pods -n kube-system
	@echo ""
	@echo "Checking pod disruption budgets..."
	@kubectl get pdb -A

backup-state: ## Backup Terraform state
	@echo "Backing up Terraform state..."
	@mkdir -p backups
	terraform state pull > backups/terraform.tfstate.$(shell date +%Y%m%d-%H%M%S).backup
	@echo "State backed up to backups/"

show-costs: ## Show estimated monthly costs
	@echo "Estimated Infrastructure Costs:"
	@echo ""
	@./cost-calculator.sh

outputs: ## Show Terraform outputs
	@terraform output

dashboard: ## Open Kubernetes Dashboard
	@echo "Starting kubectl proxy..."
	@echo "Dashboard will be available at:"
	@echo "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
	kubectl proxy

upgrade-check: ## Check for available AKS upgrades
	@echo "Checking for available Kubernetes upgrades..."
	@az aks get-upgrades --resource-group $(RESOURCE_GROUP) --name $(CLUSTER_NAME) -o table

security-scan: ## Run security scans
	@echo "Running Checkov security scan..."
	@checkov -d . --framework terraform || echo "Checkov not installed: pip install checkov"
	@echo ""
	@echo "Running TFSec security scan..."
	@tfsec . || echo "TFSec not installed: https://github.com/aquasecurity/tfsec"

start-cluster: ## Start stopped AKS cluster
	@echo "Starting AKS cluster..."
	az aks start --resource-group $(RESOURCE_GROUP) --name $(CLUSTER_NAME)

stop-cluster: ## Stop AKS cluster to save costs
	@echo "WARNING: This will stop the cluster and lose some configurations!"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		az aks stop --resource-group $(RESOURCE_GROUP) --name $(CLUSTER_NAME); \
	fi

quick-deploy: ## Quick deployment for testing (skips confirmations)
	@echo "Running quick deployment..."
	terraform init
	terraform plan -out=tfplan
	terraform apply -auto-approve tfplan
	@echo "Getting cluster credentials..."
	az aks get-credentials --resource-group $(shell terraform output -raw resource_group_name) --name $(shell terraform output -raw cluster_name)
	@echo "Quick deployment complete!"

health-check: ## Comprehensive health check
	@echo "=== Cluster Health Check ==="
	@echo ""
	@echo "Nodes Status:"
	@kubectl get nodes -o wide
	@echo ""
	@echo "Failed Pods:"
	@kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded | grep -v "Completed" || echo "None"
	@echo ""
	@echo "Node Resource Usage:"
	@kubectl top nodes 2>/dev/null || echo "Metrics server not available"
	@echo ""
	@echo "Recent Events (last 20):"
	@kubectl get events -A --sort-by='.lastTimestamp' | tail -n 20
