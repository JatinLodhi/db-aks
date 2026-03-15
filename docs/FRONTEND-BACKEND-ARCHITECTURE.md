# Frontend & Backend Node Pool Architecture

## Overview

The AKS cluster has been reconfigured to use a **dedicated node pool architecture** optimized for frontend and backend applications.

## Node Pool Structure

### 1. System Node Pool (Default)
- **Purpose**: Runs Kubernetes system components (CoreDNS, metrics-server, etc.)
- **VM Size**: Standard_D4s_v5 (4 vCPUs, 16GB RAM)
- **Scaling**: 3-6 nodes
- **Labels**: 
  - `nodepool-type=system`
  - `environment=<env>`

### 2. Frontend Node Pool
- **Purpose**: Hosts frontend/web application pods
- **VM Size**: Standard_D4s_v5 (4 vCPUs, 16GB RAM) - Default
- **Scaling**: 3-20 nodes (autoscaling enabled)
- **OS Disk**: 128GB
- **Labels**:
  - `nodepool-type=frontend`
  - `workload=frontend`
  - `app-tier=presentation`
- **Use Cases**: 
  - Web servers (React, Angular, Vue)
  - Static content serving
  - Client-side rendering
  - Web API gateways

### 3. Backend Node Pool
- **Purpose**: Hosts backend/API application pods
- **VM Size**: Standard_D4s_v5 (4 vCPUs, 16GB RAM) - Default
- **Scaling**: 3-20 nodes (autoscaling enabled)
- **OS Disk**: 256GB (larger for backend processing)
- **Labels**:
  - `nodepool-type=backend`
  - `workload=backend`
  - `app-tier=application`
- **Use Cases**:
  - REST/GraphQL APIs
  - Business logic services
  - Database connections
  - Background job processing
  - Message queue consumers

## Configuration

### Default Settings

#### Frontend Pool
```hcl
frontend_node_vm_size        = "Standard_D4s_v5"  # 4 vCPUs, 16GB RAM
frontend_node_initial_count  = 3
frontend_node_min_count      = 3
frontend_node_max_count      = 20
```

#### Backend Pool
```hcl
backend_node_vm_size         = "Standard_D4s_v5"  # 4 vCPUs, 16GB RAM
backend_node_initial_count   = 3
backend_node_min_count       = 3
backend_node_max_count       = 20
```

### Customization

You can adjust these values in `terraform.tfvars`:

```hcl
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
```

## VM Size Recommendations

### Frontend Node Sizes
| VM Size | vCPUs | RAM | Use Case |
|---------|-------|-----|----------|
| Standard_D2s_v5 | 2 | 8GB | Light frontend, static sites |
| **Standard_D4s_v5** | **4** | **16GB** | **Standard web apps (default)** |
| Standard_D8s_v5 | 8 | 32GB | Heavy traffic, complex SPAs |

### Backend Node Sizes
| VM Size | vCPUs | RAM | Use Case |
|---------|-------|-----|----------|
| **Standard_D4s_v5** | **4** | **16GB** | **Standard APIs (default)** |
| Standard_D8s_v5 | 8 | 32GB | Data-intensive APIs, heavy load |
| Standard_D16s_v5 | 16 | 64GB | Data-intensive processing |
| Standard_D32s_v5 | 32 | 128GB | Heavy computational workloads |

## Kubernetes Deployment Strategy

### Deploy Frontend Application

Use node selectors or node affinity to target the frontend pool:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      nodeSelector:
        workload: frontend
        app-tier: presentation
      containers:
      - name: frontend
        image: your-frontend-image:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
```

### Deploy Backend Application

Use node selectors for the backend pool:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      nodeSelector:
        workload: backend
        app-tier: application
      containers:
      - name: backend
        image: your-backend-image:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "1000m"
            memory: "2Gi"
          limits:
            cpu: "2000m"
            memory: "4Gi"
```

## Benefits of This Architecture

1. **Resource Isolation**: Frontend and backend workloads run on separate nodes
2. **Independent Scaling**: Scale frontend and backend independently based on demand
3. **Cost Optimization**: Use appropriate VM sizes for each workload type
4. **Better Performance**: Dedicated resources prevent resource contention
5. **Easier Troubleshooting**: Clear separation makes debugging easier
6. **Security**: Can apply different security policies to different tiers

## Autoscaling

Both node pools have **Cluster Autoscaler** enabled:

- **Frontend**: Scales from 3 to 20 nodes based on pod resource requests
- **Backend**: Scales from 3 to 20 nodes based on pod resource requests

### Horizontal Pod Autoscaler (HPA)

You can also use HPA to scale pods within each pool:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend-app
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Monitoring

All node pools send logs and metrics to Azure Log Analytics:

```bash
# View node pool status
kubectl get nodes -L workload,app-tier

# View pods by node pool
kubectl get pods -o wide --all-namespaces | grep frontend
kubectl get pods -o wide --all-namespaces | grep backend
```

## Next Steps

1. Deploy your applications with appropriate node selectors
2. Configure Horizontal Pod Autoscaler (HPA) for your workloads
3. Set up monitoring and alerts in Azure Monitor
4. Adjust node pool sizes based on actual usage patterns
5. Consider adding Pod Disruption Budgets (PDBs) for high availability

## Related Files

- Module: `modules/node-pools/`
- Variables: `variables.tf` (lines 97-148)
- Main config: `main.tf` (module.node_pools block)
- Outputs: `outputs.tf` (frontend/backend pool outputs)
