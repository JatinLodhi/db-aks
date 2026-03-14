# High-Scale AKS Cluster - Terraform Configuration

Production-grade Azure Kubernetes Service (AKS) cluster designed to handle **~500,000 total users** and **~100,000 concurrent users**.

## 📋 Architecture Overview

### Cluster Design
- **Multi-zone deployment** across 3 availability zones for high availability
- **4 node pools**:
  - **System Pool**: Dedicated for Kubernetes system components (3-6 nodes)
  - **User Pool 1**: Primary workload pool (20-150 nodes)
  - **User Pool 2**: Additional scaling capacity (20-150 nodes)
  - **High-Performance Pool**: For critical/latency-sensitive workloads (3-20 nodes)
- **Total capacity**: Up to 326 nodes (300 user + 6 system + 20 high-perf)
- **Estimated max concurrent users**: 150,000-210,000 (with safety margin)

### Key Features
✅ **Auto-scaling**: Cluster autoscaler with fine-tuned scaling profiles  
✅ **High availability**: Multi-zone deployment, multiple node pools  
✅ **Network performance**: Azure CNI for optimal pod networking  
✅ **Security**: Network policies, Azure AD RBAC, private endpoints (optional)  
✅ **Monitoring**: Azure Monitor Container Insights, Log Analytics  
✅ **Container registry**: Premium ACR with geo-replication  
✅ **Load balancing**: Standard Load Balancer with multiple outbound IPs  

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

### Deployment Steps

1. **Clone and configure**
```bash
cd aks-terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

2. **Initialize Terraform**
```bash
terraform init
```

3. **Review the plan**
```bash
terraform plan -out=tfplan
```

4. **Deploy the cluster**
```bash
terraform apply tfplan
```

Deployment typically takes **15-25 minutes**.

5. **Get cluster credentials**
```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw cluster_name)
```

6. **Verify deployment**
```bash
kubectl get nodes
kubectl get pods -A
```

## ⚙️ Configuration

### Capacity Planning

**User Node Pool Sizing (per pool)**:
| VM Size | vCPU | RAM | Est. Users/Node | Min Nodes | Max Nodes | Max Users |
|---------|------|-----|-----------------|-----------|-----------|-----------|
| D4s_v5  | 4    | 16GB | 250-350        | 20        | 150       | 37.5k-52.5k |
| D8s_v5  | 8    | 32GB | 500-700        | 20        | 150       | 75k-105k |
| D16s_v5 | 16   | 64GB | 1000-1400      | 20        | 150       | 150k-210k |

**Total Capacity (with 2 user pools)**:
- **D8s_v5** (default): 150k-210k concurrent users
- **D16s_v5**: 300k-420k concurrent users

### Key Variables to Customize

```hcl
# In terraform.tfvars

# Adjust VM size based on your workload
user_node_vm_size = "Standard_D8s_v5"

# Adjust node counts based on expected traffic
user_node_initial_count = 30  # Start capacity
user_node_min_count     = 20  # Minimum always running
user_node_max_count     = 150 # Maximum scale-out

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

### 1. Deploy Horizontal Pod Autoscaler (HPA)
```yaml
# hpa-example.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: your-app
  minReplicas: 10
  maxReplicas: 500
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### 2. Configure Pod Disruption Budgets
```yaml
# pdb-example.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 70%
  selector:
    matchLabels:
      app: your-app
```

### 3. Set Resource Requests/Limits
```yaml
# deployment-example.yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 4. Deploy Ingress Controller
```bash
# NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=3 \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=128Mi
```

### 5. Configure Cluster Autoscaler Priorities
```bash
# Node pool with higher priority gets scaled first
kubectl annotate nodepool user_pool_1 \
  cluster-autoscaler.kubernetes.io/priority=100

kubectl annotate nodepool user_pool_2 \
  cluster-autoscaler.kubernetes.io/priority=90
```

## 💰 Cost Optimization

### Estimated Monthly Costs (East US region)
| Component | Configuration | Est. Monthly Cost |
|-----------|---------------|------------------|
| System Pool | 3x D4s_v5 | ~$350 |
| User Pool 1 (min) | 20x D8s_v5 | ~$4,600 |
| User Pool 2 (min) | 20x D8s_v5 | ~$4,600 |
| High-Perf Pool | 3x D16s_v5 | ~$1,050 |
| ACR Premium | Geo-replicated | ~$250 |
| Log Analytics | 30-day retention | ~$200-500 |
| **Total (minimum)** | | **~$11,000-11,500** |
| **Total (at max scale)** | 326 nodes | **~$75,000** |

### Cost Reduction Strategies
1. **Use Spot VMs** for non-critical workloads (60-80% savings)
2. **Reserved Instances** for baseline capacity (40-60% savings)
3. **Right-size VMs** based on actual usage patterns
4. **Implement aggressive autoscaling** to scale down during off-peak
5. **Use smaller VM SKUs** if workload allows (D4s_v5 instead of D8s_v5)

### Add Spot Node Pool (Example)
```hcl
# Add to main.tf
resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size              = "Standard_D8s_v5"
  priority             = "Spot"
  eviction_policy      = "Delete"
  spot_max_price       = -1  # Pay up to on-demand price
  enable_auto_scaling  = true
  min_count            = 5
  max_count            = 100
  
  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }
  
  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]
}
```

## 🔧 Troubleshooting

### Common Issues

**1. SNAT Port Exhaustion (High Concurrency)**
```bash
# Symptom: Intermittent connection failures
# Solution: Already configured with 4 outbound IPs
# Monitor: Check Azure Monitor for SNAT metrics
```

**2. Cluster Autoscaler Not Scaling**
```bash
# Check autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler

# Common causes:
# - Insufficient quota
# - Max node count reached
# - Pending pods don't have resource requests
```

**3. Pod Scheduling Failures**
```bash
# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"
```

**4. High Memory/CPU Usage**
```bash
# Top resource-consuming pods
kubectl top pods -A --sort-by=memory
kubectl top pods -A --sort-by=cpu

# Top resource-consuming nodes
kubectl top nodes
```

## 📚 Additional Resources

### Application Optimization for Scale
1. **Implement caching** (Redis, Memcached)
2. **Use CDN** for static assets
3. **Database connection pooling**
4. **Async processing** for heavy tasks
5. **Rate limiting** to prevent abuse
6. **Session management** (Redis for distributed sessions)

### Recommended Kubernetes Add-ons
- **Prometheus + Grafana**: Advanced monitoring
- **Cert-Manager**: Automated SSL/TLS certificates
- **External-DNS**: Automated DNS management
- **Keda**: Event-driven autoscaling
- **Istio/Linkerd**: Service mesh for advanced traffic management

### Performance Testing
```bash
# Load testing with k6
k6 run --vus 10000 --duration 30m load-test.js

# Monitor during test
watch -n 1 kubectl top nodes
watch -n 1 kubectl top pods
```

## 🔄 Upgrades & Maintenance

### Kubernetes Version Upgrades
```bash
# Check available versions
az aks get-upgrades --resource-group <rg> --name <cluster>

# Upgrade cluster (use Terraform)
# Update kubernetes_version in variables.tf
terraform plan
terraform apply
```

### Node Pool Upgrades
```bash
# Upgrade is automatic during cluster upgrade
# Or manually trigger
az aks nodepool upgrade \
  --resource-group <rg> \
  --cluster-name <cluster> \
  --name userpool1 \
  --kubernetes-version 1.28
```

## 📞 Support & Contributions

For issues or questions:
1. Check Azure AKS documentation
2. Review Terraform AzureRM provider docs
3. Check cluster events and logs
4. Contact your Azure support team

## 📄 License

This Terraform configuration is provided as-is for infrastructure deployment.

---

**Deployment Checklist:**
- [ ] Updated terraform.tfvars with your values
- [ ] Configured Azure AD admin groups
- [ ] Set API server authorized IP ranges
- [ ] Reviewed and adjusted node pool sizes
- [ ] Planned for cost monitoring and budgets
- [ ] Prepared application deployment manifests
- [ ] Set up monitoring alerts
- [ ] Documented runbooks for incidents
- [ ] Tested disaster recovery procedures
- [ ] Scheduled regular security reviews
