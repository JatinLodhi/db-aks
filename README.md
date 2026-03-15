# AKS Terraform Infrastructure

Production-grade Azure Kubernetes Service (AKS) cluster with modular Terraform architecture, optimized for frontend and backend applications.

## 📋 Architecture Overview

### Cluster Design
- **Multi-zone deployment** across 3 availability zones for high availability
- **3 node pools**:
  - **System Pool**: Dedicated for Kubernetes system components (3-6 nodes)
  - **Frontend Pool**: Optimized for web/frontend workloads (3-20 nodes)
  - **Backend Pool**: Optimized for API/backend workloads (3-20 nodes)
- **Auto-scaling**: Cluster autoscaler with fine-tuned scaling profiles
- **Modular structure**: Organized into reusable Terraform modules

### Key Features
✅ **Auto-scaling**: Cluster autoscaler with fine-tuned scaling profiles  
✅ **High availability**: Multi-zone deployment, dedicated node pools  
✅ **Network performance**: Azure CNI for optimal pod networking  
✅ **Security**: Network policies, Azure AD RBAC, role-based access  
✅ **Monitoring**: Azure Monitor Container Insights, Log Analytics  
✅ **Container registry**: Premium ACR with geo-replication  
✅ **Load balancing**: Standard Load Balancer with multiple outbound IPs  
✅ **CI/CD Ready**: GitHub Actions workflow included

## 📁 Repository Structure

```
db-aks/
├── .github/
│   └── workflows/
│       └── terraform.yml          # GitHub Actions CI/CD pipeline
├── docs/                          # Documentation
│   ├── FRONTEND-BACKEND-ARCHITECTURE.md
│   ├── GITHUB-ACTIONS-SETUP.md
│   ├── MODULE-STRUCTURE.md
│   ├── PROJECT-SUMMARY.md
│   ├── QUICK-REFERENCE.md
│   └── TROUBLESHOOTING.md
├── environments/                  # Environment-specific configs
│   ├── development.tfvars
│   ├── main.tfvars
│   ├── backend-development.tfvars
│   └── backend-main.tfvars
├── examples/                      # Kubernetes example manifests
│   ├── deployment-example.yaml
│   ├── hpa-examples.yaml
│   └── pdb-examples.yaml
├── modules/                       # Terraform modules
│   ├── aks-cluster/
│   ├── container-registry/
│   ├── identity/
│   ├── monitoring/
│   ├── networking/
│   ├── node-pools/
│   └── resource-group/
├── scripts/                       # Utility scripts
│   ├── cost-calculator.sh
│   ├── deploy.sh
│   ├── load-test.js
│   ├── Makefile
│   └── monitoring-alerts.sh
├── backend.tf                     # Backend configuration
├── main.tf                        # Root module
├── outputs.tf                     # Root outputs
├── variables.tf                   # Root variables
├── terraform.tfvars.example       # Example configuration
└── README.md                      # This file
```

## 🚀 Quick Start

### Prerequisites
```bash
# Required tools
- Azure CLI >= 2.50.0
- Terraform >= 1.0
- kubectl >= 1.28

# Login to Azure
az login
az account set --subscription "<your-subscription-id>"
```

### Local Deployment

1. **Clone and configure**
```bash
cd db-aks
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

2. **Initialize Terraform**
```bash
## 🚀 Deployment Options

### Option 1: GitHub Actions (Recommended)

This repository includes a complete CI/CD pipeline with GitHub Actions.

**Setup Steps**:
1. Configure Azure service principal and GitHub secrets
2. Push to `main` or `development` branch
3. Review and approve the Terraform plan
4. Automated deployment to Azure

See [docs/GITHUB-ACTIONS-SETUP.md](docs/GITHUB-ACTIONS-SETUP.md) for complete setup instructions.

### Option 2: Local Deployment

For local testing or manual deployments:

```bash
# Initialize with environment-specific configuration
terraform init \
  -var-file=environments/development.tfvars \
  -backend-config=environments/backend-development.tfvars

# Plan changes
terraform plan -var-file=environments/development.tfvars

# Apply changes
terraform apply -var-file=environments/development.tfvars
```

### Deployment Time

Typical deployment takes **15-25 minutes** for a new cluster.

### Post-Deployment

Get cluster credentials:
```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw cluster_name)
```

Verify deployment:
```bash
kubectl get nodes -L workload,app-tier
kubectl get pods -A
```

## ⚙️ Configuration

### Node Pool Architecture

The cluster uses dedicated node pools for frontend and backend workloads:

**Frontend Node Pool**:
- **VM Size**: Standard_D4s_v5 (4 vCPUs, 16GB RAM)
- **Scaling**: 3-20 nodes
- **Purpose**: Web servers, SPAs, frontend applications
- **Node Labels**: `workload=frontend`, `app-tier=presentation`

**Backend Node Pool**:
- **VM Size**: Standard_D4s_v5 (4 vCPUs, 16GB RAM)
- **Scaling**: 3-20 nodes
- **Purpose**: APIs, business logic, backend services
- **Node Labels**: `workload=backend`, `app-tier=application`

See [docs/FRONTEND-BACKEND-ARCHITECTURE.md](docs/FRONTEND-BACKEND-ARCHITECTURE.md) for detailed information.

### Key Variables to Customize

```hcl
# In terraform.tfvars or environments/*.tfvars

# Frontend Configuration
frontend_node_vm_size       = "Standard_D4s_v5"
frontend_node_initial_count = 3
frontend_node_min_count     = 3
frontend_node_max_count     = 20

# Backend Configuration
backend_node_vm_size        = "Standard_D4s_v5"
backend_node_initial_count  = 3
backend_node_min_count      = 3
backend_node_max_count      = 20

# Security: Restrict API server access
api_server_authorized_ip_ranges = ["1.2.3.4/32"]

# Azure AD admin groups
admin_group_object_ids = ["your-group-object-id"]
```

## 🔐 Security Best Practices

1. **API Server Access**
   ```hcl
   # Restrict to your IP ranges
   api_server_authorized_ip_ranges = [
     "1.2.3.4/32",  # Office IP
     "5.6.7.8/32",  # CI/CD IP
   ]
   ```

2. **Azure AD Integration**
   - Enable Azure AD RBAC
   - Assign least-privilege roles
   - Use managed identities

3. **Network Policies**
   - Enabled by default (Azure Network Policy)
   - Implement pod-to-pod security

4. **Container Security**
   - Scan images in ACR
   - Use private endpoints for ACR
   - Enable Azure Defender for Containers

## 📊 Monitoring & Observability

### Built-in Monitoring
- **Azure Monitor Container Insights**: Enabled by default
- **Log Analytics**: 30-day retention (configurable)
- **Metrics**: CPU, memory, disk, network per node/pod
- **Logs**: Container logs, Kubernetes events

### Recommended Dashboards
```bash
# View in Azure Portal
az aks show --resource-group <rg> --name <cluster> --query id

# Or use Azure Monitor Workbooks
```

### Key Metrics to Monitor
- Node CPU/Memory utilization
- Pod restart count
- Network ingress/egress
- SNAT port usage (important for high concurrency!)
- API server latency
- Cluster autoscaler events

## 🔄 Post-Deployment Configuration

### 1. Deploy Your Applications

Deploy frontend applications to frontend nodes:
```yaml
# See examples/deployment-example.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
spec:
  replicas: 3
  template:
    spec:
      nodeSelector:
        workload: frontend
        app-tier: presentation
      containers:
      - name: frontend
        image: your-frontend-image:latest
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
```

Deploy backend applications to backend nodes:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
spec:
  replicas: 5
  template:
    spec:
      nodeSelector:
        workload: backend
        app-tier: application
      containers:
      - name: backend
        image: your-backend-image:latest
        resources:
          requests:
            cpu: "1000m"
            memory: "2Gi"
          limits:
            cpu: "2000m"
            memory: "4Gi"
```

### 2. Configure Horizontal Pod Autoscaler (HPA)

See [examples/hpa-examples.yaml](examples/hpa-examples.yaml) for complete examples.

```bash
kubectl apply -f examples/hpa-examples.yaml
```

### 3. Configure Pod Disruption Budgets (PDB)

See [examples/pdb-examples.yaml](examples/pdb-examples.yaml) for complete examples.

```bash
kubectl apply -f examples/pdb-examples.yaml
```

### 4. Deploy Ingress Controller

```bash
# NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=3 \
  --set controller.nodeSelector."workload"=frontend \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=128Mi
```

## 💰 Cost Optimization

### Estimated Monthly Costs (East US region)

| Component | Configuration | Est. Monthly Cost |
|-----------|---------------|------------------|
| System Pool | 3x D4s_v5 | ~$350 |
| Frontend Pool (min) | 3x D4s_v5 | ~$525 |
| Backend Pool (min) | 3x D4s_v5 | ~$525 |
| ACR Premium | Geo-replicated | ~$250 |
| Log Analytics | 30-day retention | ~$200-500 |
| **Total (minimum)** | | **~$1,850-2,350** |
| **Total (at max scale)** | 46 nodes | **~$8,000-9,000** |

### Cost Reduction Strategies

1. **Right-size Node Pools** based on actual usage patterns
2. **Use Reserved Instances** for baseline capacity (up to 60% savings)
3. **Implement Aggressive Autoscaling** to scale down during off-peak hours
4. **Use Spot VMs** for non-critical workloads (up to 80% savings)
5. **Optimize Log Retention** - reduce to 7-14 days if logs are exported
6. **Use Cheaper Regions** if latency allows

### Cost Monitoring

Use the cost calculator script:
```bash
./scripts/cost-calculator.sh
```

Monitor costs in Azure Portal or use Azure Cost Management.

## 🔧 Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for comprehensive troubleshooting guide.

### Quick Diagnostics

**Check node status:**
```bash
kubectl get nodes -L workload,app-tier
kubectl describe node <node-name>
```

**Check pod issues:**
```bash
kubectl get events --sort-by='.lastTimestamp'
kubectl get pods -A | grep -v Running
kubectl describe pod <pod-name> -n <namespace>
```

**Check resource usage:**
```bash
kubectl top nodes
kubectl top pods -A --sort-by=memory
kubectl top pods -A --sort-by=cpu
```

**Check cluster autoscaler:**
```bash
kubectl logs -n kube-system -l app=cluster-autoscaler
```

### Common Issues

1. **Pods not scheduling on specific node pool**
   - Verify node labels: `kubectl get nodes --show-labels`
   - Check nodeSelector in deployment manifest
   - Ensure nodes are Ready

2. **Autoscaler not scaling**
   - Check pod resource requests are set
   - Verify max node count not reached
   - Check autoscaler logs for errors

3. **High memory/CPU usage**
   - Review resource requests/limits
   - Check for memory leaks
   - Consider scaling up VM size

## 📚 Documentation

- [Frontend/Backend Architecture](docs/FRONTEND-BACKEND-ARCHITECTURE.md)
- [Module Structure](docs/MODULE-STRUCTURE.md)
- [GitHub Actions Setup](docs/GITHUB-ACTIONS-SETUP.md)
- [Quick Reference Guide](docs/QUICK-REFERENCE.md)
- [Project Summary](docs/PROJECT-SUMMARY.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

## 🛠️ Utilities

### Scripts

Located in the `scripts/` directory:

- **cost-calculator.sh** - Calculate estimated monthly costs
- **deploy.sh** - Automated deployment script
- **monitoring-alerts.sh** - Set up monitoring alerts
- **load-test.js** - Load testing script (k6)
- **Makefile** - Common commands and workflows

### Kubernetes Examples

Located in the `examples/` directory:

- **deployment-example.yaml** - Sample deployment manifests
- **hpa-examples.yaml** - Horizontal Pod Autoscaler configurations
- **pdb-examples.yaml** - Pod Disruption Budget examples

### Performance Testing

Run load tests using the provided script:
```bash
# Install k6 first: https://k6.io/docs/getting-started/installation/
k6 run scripts/load-test.js
```

Monitor during test:
```bash
watch -n 1 kubectl top nodes
watch -n 1 kubectl get hpa
```

## 🔄 Upgrades & Maintenance

### Kubernetes Version Upgrades

Update the Kubernetes version in your environment tfvars:

```hcl
# In environments/main.tfvars
kubernetes_version = "1.29"  # Updated version
```

Then apply via Terraform or GitHub Actions:
```bash
terraform plan -var-file=environments/main.tfvars
terraform apply -var-file=environments/main.tfvars
```

### Check Available Versions

```bash
az aks get-upgrades \
  --resource-group <resource-group> \
  --name <cluster-name>
```

### Maintenance Windows

Cluster maintenance is configured to run:
- **Day**: Sunday
- **Time**: 2-5 AM UTC

Configure in [modules/aks-cluster/main.tf](modules/aks-cluster/main.tf)

## 🧹 Cleanup

### Destroy Infrastructure

```bash
# Via Terraform
terraform destroy -var-file=environments/development.tfvars

# Or for specific environment
terraform destroy -var-file=environments/main.tfvars
```

### Remove Backend State

If destroying everything:
```bash
# Delete the storage account (after destroying infrastructure)
az group delete --name terraform-state-rg
```

## 📞 Support

For questions or issues:
- Review [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- Check [docs/QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)
- Review Azure AKS documentation
- Check GitHub Issues for this repository

## 📄 License

This Terraform configuration is provided as-is for infrastructure deployment.

---

## ✅ Deployment Checklist

Before deploying to production:

- [ ] Review and customize `environments/main.tfvars`
- [ ] Configure Azure backend storage for Terraform state
- [ ] Set up GitHub Actions secrets and variables
- [ ] Configure Azure AD admin groups
- [ ] Set API server authorized IP ranges (if needed)
- [ ] Review and adjust node pool sizes
- [ ] Set up cost monitoring and budgets in Azure
- [ ] Prepare application deployment manifests with node selectors
- [ ] Configure monitoring alerts
- [ ] Document incident response procedures
- [ ] Test autoscaling behavior
- [ ] Perform load testing in non-production
- [ ] Plan backup and disaster recovery strategy
- [ ] Schedule regular security reviews
- [ ] Set up log aggregation and retention policy

## 🎯 Quick Links

- **Repository Structure**: [Module Organization](docs/MODULE-STRUCTURE.md)
- **CI/CD Setup**: [GitHub Actions Guide](docs/GITHUB-ACTIONS-SETUP.md)
- **Node Pools**: [Architecture Details](docs/FRONTEND-BACKEND-ARCHITECTURE.md)
- **Commands**: [Quick Reference](docs/QUICK-REFERENCE.md)
- **Help**: [Troubleshooting](docs/TROUBLESHOOTING.md)
