# AKS High-Scale Cluster - Quick Reference Guide

## Deployment Commands

```bash
# Initial setup
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration

# Deploy cluster (automated)
./deploy.sh

# Or manual deployment
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Get cluster credentials
az aks get-credentials --resource-group <rg-name> --name <cluster-name>
```

## Cluster Management

```bash
# View nodes
kubectl get nodes
kubectl get nodes -o wide

# View node resource usage
kubectl top nodes

# Describe a node
kubectl describe node <node-name>

# Cordon a node (prevent new pods)
kubectl cordon <node-name>

# Drain a node (for maintenance)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Uncordon a node
kubectl uncordon <node-name>
```

## Pod & Deployment Management

```bash
# View pods across all namespaces
kubectl get pods -A
kubectl get pods -A -o wide

# View pod resource usage
kubectl top pods -A
kubectl top pods -n production

# Describe a pod
kubectl describe pod <pod-name> -n <namespace>

# View pod logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # Previous crashed container

# Exec into a pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Scale a deployment
kubectl scale deployment <deployment-name> -n <namespace> --replicas=10

# View deployment status
kubectl rollout status deployment/<deployment-name> -n <namespace>

# View deployment history
kubectl rollout history deployment/<deployment-name> -n <namespace>

# Rollback deployment
kubectl rollout undo deployment/<deployment-name> -n <namespace>
```

## Autoscaling

```bash
# View HPA status
kubectl get hpa -A
kubectl describe hpa <hpa-name> -n <namespace>

# View cluster autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler

# View cluster autoscaler events
kubectl get events -n kube-system | grep cluster-autoscaler

# Manually trigger scale-up (for testing)
kubectl scale deployment <deployment-name> --replicas=200 -n <namespace>
```

## Monitoring & Troubleshooting

```bash
# View cluster events
kubectl get events -A --sort-by='.lastTimestamp'
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# View failed pods
kubectl get pods -A --field-selector=status.phase=Failed

# View pending pods
kubectl get pods -A --field-selector=status.phase=Pending

# Check resource quotas
kubectl describe resourcequota -n <namespace>

# Check pod disruption budgets
kubectl get pdb -A

# View service endpoints
kubectl get endpoints -A

# View ingress rules
kubectl get ingress -A

# Network troubleshooting
kubectl run debug --rm -i --tty --image=nicolaka/netshoot -- /bin/bash
```

## Azure-Specific Commands

```bash
# View AKS cluster details
az aks show --resource-group <rg-name> --name <cluster-name>

# View available Kubernetes versions
az aks get-versions --location eastus

# Check available upgrades
az aks get-upgrades --resource-group <rg-name> --name <cluster-name>

# Start AKS cluster
az aks start --resource-group <rg-name> --name <cluster-name>

# Stop AKS cluster (saves costs but loses configurations)
az aks stop --resource-group <rg-name> --name <cluster-name>

# View node pool details
az aks nodepool list --resource-group <rg-name> --cluster-name <cluster-name>

# Scale node pool manually
az aks nodepool scale \
  --resource-group <rg-name> \
  --cluster-name <cluster-name> \
  --name <nodepool-name> \
  --node-count 50

# Add new node pool
az aks nodepool add \
  --resource-group <rg-name> \
  --cluster-name <cluster-name> \
  --name <new-pool-name> \
  --node-count 10 \
  --node-vm-size Standard_D8s_v5 \
  --enable-cluster-autoscaler \
  --min-count 10 \
  --max-count 100
```

## Container Registry (ACR)

```bash
# Login to ACR
az acr login --name <acr-name>

# List images
az acr repository list --name <acr-name>

# View image tags
az acr repository show-tags --name <acr-name> --repository <image-name>

# Build and push image
docker build -t <acr-name>.azurecr.io/<image-name>:tag .
docker push <acr-name>.azurecr.io/<image-name>:tag

# Import image from Docker Hub to ACR
az acr import \
  --name <acr-name> \
  --source docker.io/library/nginx:latest \
  --image nginx:latest
```

## Cost Management

```bash
# View current month costs
az consumption usage list \
  --start-date $(date -d "$(date +%Y-%m-01)" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d)

# View resource costs
az cost-management query \
  --type Usage \
  --dataset-filter "{\"dimensions\":{\"name\":\"ResourceGroup\",\"operator\":\"In\",\"values\":[\"<rg-name>\"]}}"

# Set budget alert
az consumption budget create \
  --amount 15000 \
  --category Cost \
  --name aks-monthly-budget \
  --time-grain Monthly \
  --resource-group <rg-name>
```

## Disaster Recovery

```bash
# Backup cluster configuration
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Export Terraform state
terraform state pull > terraform.tfstate.backup

# Snapshot persistent volumes
az snapshot create \
  --resource-group <rg-name> \
  --name <snapshot-name> \
  --source <disk-id>

# Restore from snapshot
az disk create \
  --resource-group <rg-name> \
  --name <restored-disk> \
  --source <snapshot-id>
```

## Performance Testing

```bash
# Install k6 load testing tool
brew install k6  # macOS
# or download from https://k6.io

# Run load test
k6 run --vus 1000 --duration 10m load-test.js

# Monitor during load test
watch -n 1 kubectl top nodes
watch -n 1 kubectl top pods -n production
```

## Common Issues & Solutions

### Issue: Pods stuck in Pending
```bash
# Check events
kubectl describe pod <pod-name> -n <namespace>

# Common causes:
# - Insufficient resources
# - Node selector mismatch
# - PVC not available
# - Image pull failure

# Solutions:
kubectl get events -n <namespace>
kubectl describe nodes
kubectl get pv
```

### Issue: High memory/CPU on nodes
```bash
# Identify resource hogs
kubectl top pods -A --sort-by=memory
kubectl top pods -A --sort-by=cpu

# Check resource requests/limits
kubectl describe pod <pod-name> -n <namespace> | grep -A 5 "Limits"

# Consider:
# - Increase node pool size
# - Optimize application
# - Add resource limits
```

### Issue: Cluster autoscaler not scaling
```bash
# Check autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=100

# Common issues:
# - Max nodes reached
# - Quota limits
# - Pending pods without resource requests

# Verify:
kubectl get nodes
kubectl describe nodes | grep "Allocated resources" -A 10
```

### Issue: SNAT port exhaustion (high concurrency)
```bash
# Symptoms: Connection timeouts, intermittent failures

# Check outbound connections
az network lb outbound-rule list \
  --resource-group <node-rg> \
  --lb-name <lb-name>

# Solutions:
# - Increase outbound IPs (already configured with 4)
# - Implement connection pooling in applications
# - Use Azure NAT Gateway
# - Reduce external API calls
```

## Security Best Practices

```bash
# Scan images for vulnerabilities
az acr task run \
  --registry <acr-name> \
  --name <task-name>

# View vulnerability scan results
az acr task show \
  --registry <acr-name> \
  --name <task-name>

# Enable Azure Defender for Containers
az security pricing create \
  --name KubernetesService \
  --tier Standard

# Check for security recommendations
az security assessment list

# Rotate service principal credentials (if using)
az aks update-credentials \
  --resource-group <rg-name> \
  --name <cluster-name> \
  --reset-service-principal
```

## Useful Aliases

Add these to your `.bashrc` or `.zshrc`:

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kgd='kubectl get deployments'
alias kgs='kubectl get services'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kx='kubectl exec -it'
alias ktn='kubectl top nodes'
alias ktp='kubectl top pods'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
```

## Emergency Procedures

### Complete Cluster Failure
1. Check Azure Service Health
2. Verify subscription status
3. Check control plane logs in Azure Monitor
4. Contact Azure Support
5. Consider deploying to disaster recovery region

### Performance Degradation
1. Check node resource usage: `kubectl top nodes`
2. Check pod resource usage: `kubectl top pods -A`
3. Review recent deployments: `kubectl rollout history`
4. Check cluster autoscaler: `kubectl logs -n kube-system -l app=cluster-autoscaler`
5. Scale up manually if needed: `az aks nodepool scale`

### Security Incident
1. Isolate affected workloads
2. Review audit logs in Azure Monitor
3. Rotate all credentials
4. Scan all images for vulnerabilities
5. Review network policies and firewall rules
6. Engage security team

## Additional Resources

- [AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Monitor](https://docs.microsoft.com/azure/azure-monitor/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
