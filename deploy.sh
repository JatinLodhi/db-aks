#!/bin/bash
set -e

# AKS High-Scale Cluster Deployment Script
# This script automates the deployment and initial setup of the AKS cluster

echo "=========================================="
echo "AKS High-Scale Cluster Deployment"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Check prerequisites
echo "Checking prerequisites..."

# Check Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi
print_success "Azure CLI found"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi
print_success "Terraform found"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed. You'll need it to manage the cluster."
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Please run 'az login' first."
    exit 1
fi
print_success "Logged in to Azure"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
print_info "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Ask for confirmation
echo ""
read -p "Continue with deployment? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_warning "terraform.tfvars not found. Creating from example..."
    cp terraform.tfvars.example terraform.tfvars
    print_error "Please edit terraform.tfvars with your configuration and run this script again."
    exit 1
fi

# Initialize Terraform
echo ""
print_info "Initializing Terraform..."
terraform init
if [ $? -eq 0 ]; then
    print_success "Terraform initialized"
else
    print_error "Terraform initialization failed"
    exit 1
fi

# Validate Terraform configuration
echo ""
print_info "Validating Terraform configuration..."
terraform validate
if [ $? -eq 0 ]; then
    print_success "Configuration valid"
else
    print_error "Configuration validation failed"
    exit 1
fi

# Plan deployment
echo ""
print_info "Creating Terraform plan..."
terraform plan -out=tfplan
if [ $? -ne 0 ]; then
    print_error "Terraform plan failed"
    exit 1
fi

# Show estimated costs
echo ""
print_warning "IMPORTANT: This deployment will create Azure resources that will incur costs."
print_info "Estimated minimum monthly cost: ~\$11,000-11,500"
print_info "Estimated maximum monthly cost (at full scale): ~\$75,000"
echo ""

# Confirm deployment
read -p "Do you want to proceed with deployment? (yes/no): " DEPLOY_CONFIRM
if [ "$DEPLOY_CONFIRM" != "yes" ]; then
    echo "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

# Apply Terraform
echo ""
print_info "Deploying AKS cluster... (this will take 15-25 minutes)"
terraform apply tfplan
if [ $? -eq 0 ]; then
    print_success "Cluster deployed successfully!"
else
    print_error "Deployment failed"
    exit 1
fi

# Get cluster information
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw cluster_name)
ACR_NAME=$(terraform output -raw acr_name 2>/dev/null || echo "")

# Get AKS credentials
echo ""
print_info "Getting cluster credentials..."
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    --overwrite-existing

if [ $? -eq 0 ]; then
    print_success "Credentials configured"
else
    print_error "Failed to get credentials"
    exit 1
fi

# Verify cluster access
echo ""
print_info "Verifying cluster access..."
kubectl get nodes
if [ $? -eq 0 ]; then
    print_success "Successfully connected to cluster"
else
    print_error "Failed to connect to cluster"
    exit 1
fi

# Install additional components
echo ""
print_info "Installing additional cluster components..."

# Create production namespace
echo ""
print_info "Creating production namespace..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
print_success "Production namespace created"

# Apply PodDisruptionBudgets
if [ -f "k8s-manifests/pdb-examples.yaml" ]; then
    echo ""
    print_info "Applying Pod Disruption Budgets..."
    kubectl apply -f k8s-manifests/pdb-examples.yaml
    print_success "PDBs applied"
fi

# Install NGINX Ingress Controller
echo ""
read -p "Install NGINX Ingress Controller? (yes/no): " INSTALL_NGINX
if [ "$INSTALL_NGINX" == "yes" ]; then
    print_info "Installing NGINX Ingress Controller..."
    
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    helm install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.replicaCount=3 \
        --set controller.nodeSelector."kubernetes\.io/os"=linux \
        --set controller.resources.requests.cpu=100m \
        --set controller.resources.requests.memory=128Mi \
        --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
    
    print_success "NGINX Ingress Controller installed"
fi

# Install cert-manager
echo ""
read -p "Install cert-manager for TLS certificates? (yes/no): " INSTALL_CERT
if [ "$INSTALL_CERT" == "yes" ]; then
    print_info "Installing cert-manager..."
    
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    print_success "cert-manager installed"
fi

# Configure ACR integration (if ACR was created)
if [ -n "$ACR_NAME" ]; then
    echo ""
    print_info "ACR Login Server: $(terraform output -raw acr_login_server)"
    print_info "To push images to ACR, run: az acr login --name $ACR_NAME"
fi

# Display cluster information
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
print_success "Cluster Name: $CLUSTER_NAME"
print_success "Resource Group: $RESOURCE_GROUP"
print_success "Kubernetes Version: $(kubectl version --short 2>/dev/null | grep Server || echo 'N/A')"
print_success "Total Nodes: $(kubectl get nodes --no-headers | wc -l)"

if [ -n "$ACR_NAME" ]; then
    print_success "Container Registry: $ACR_NAME"
fi

echo ""
echo "Next Steps:"
echo "1. Deploy your applications using kubectl or Helm"
echo "2. Configure Horizontal Pod Autoscalers (see k8s-manifests/hpa-examples.yaml)"
echo "3. Set up monitoring alerts (see k8s-manifests/monitoring-alerts.sh)"
echo "4. Configure CI/CD pipelines to deploy to this cluster"
echo "5. Set up cost monitoring and budgets in Azure Portal"
echo ""

echo "Useful Commands:"
echo "  kubectl get nodes                    # View cluster nodes"
echo "  kubectl get pods -A                  # View all pods"
echo "  kubectl top nodes                    # View node resource usage"
echo "  kubectl top pods -A                  # View pod resource usage"
echo "  kubectl cluster-info                 # View cluster information"
echo ""

echo "Terraform Outputs:"
terraform output

echo ""
print_warning "Remember to monitor costs in Azure Portal!"
print_warning "Set up budget alerts to avoid unexpected charges."
echo ""
