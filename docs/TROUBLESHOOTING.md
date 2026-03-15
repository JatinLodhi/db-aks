# AKS High-Scale Troubleshooting Guide

## Table of Contents
1. [Deployment Issues](#deployment-issues)
2. [Scaling Problems](#scaling-problems)
3. [Network Issues](#network-issues)
4. [Performance Problems](#performance-problems)
5. [Pod Scheduling Failures](#pod-scheduling-failures)
6. [Resource Exhaustion](#resource-exhaustion)
7. [Application Issues](#application-issues)
8. [Monitoring & Observability](#monitoring--observability)

---

## Deployment Issues

### Terraform Deployment Fails

**Problem**: Terraform apply fails with various errors

**Common Causes & Solutions**:

1. **Quota Limits Exceeded**
   ```bash
   # Check current quotas
   az vm list-usage --location eastus -o table
   
   # Request quota increase
   az support tickets create \
     --ticket-name "AKS-Quota-Increase" \
     --issue-type quota \
     --severity 2
   ```

2. **Insufficient Permissions**
   ```bash
   # Verify service principal permissions
   az role assignment list --assignee <service-principal-id>
   
   # Required roles:
   # - Contributor on subscription or resource group
   # - Network Contributor for VNet operations
   ```

3. **Resource Name Conflicts**
   ```bash
   # Check if resources already exist
   az resource list --name <resource-name>
   
   # Solution: Change cluster_name in terraform.tfvars
   ```

4. **Backend State Lock**
   ```bash
   # Check if state is locked
   az storage blob show \
     --account-name <storage-account> \
     --container-name <container> \
     --name <key>
   
   # Force unlock (DANGEROUS - ensure no other operations running!)
   terraform force-unlock <lock-id>
   ```

---

## Scaling Problems

### Cluster Autoscaler Not Scaling Up

**Problem**: Pods remain in Pending state even though autoscaler is enabled

**Diagnosis**:
```bash
# Check autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=100

# Check pending pods
kubectl get pods -A --field-selector=status.phase=Pending

# Check events
kubectl get events -A | grep -i "failedscheduling"
```

**Common Causes**:

1. **No Resource Requests Set**
   - Autoscaler can't determine pod resource needs
   - Solution: Add resource requests to all pods
   ```yaml
   resources:
     requests:
       cpu: 100m
       memory: 128Mi
   ```

2. **Max Node Count Reached**
   ```bash
   # Check current node count
   kubectl get nodes | wc -l
   
   # Check max count in Terraform
   grep user_node_max_count terraform.tfvars
   
   # Solution: Increase max_count in variables
   ```

3. **Quota Limits**
   ```bash
   # Check if hitting quota
   az vm list-usage --location eastus --output table | grep -i "total regional vcpus"
   
   # Request increase via Azure Portal
   ```

4. **Unschedulable Nodes**
   ```bash
   # Check node conditions
   kubectl describe nodes | grep -A 5 "Conditions"
   
   # Look for: DiskPressure, MemoryPressure, PIDPressure
   ```

### Cluster Autoscaler Scaling Down Too Aggressively

**Problem**: Nodes being removed even when still needed

**Solution**:
```bash
# Adjust autoscaler parameters in main.tf
auto_scaler_profile {
  scale_down_unneeded = "15m"  # Increase from 10m
  scale_down_utilization_threshold = "0.4"  # Lower from 0.5
}

# Or add annotation to prevent specific node removal
kubectl annotate node <node-name> \
  cluster-autoscaler.kubernetes.io/scale-down-disabled=true
```

### HPA Not Scaling Pods

**Problem**: Horizontal Pod Autoscaler not creating new pods

**Diagnosis**:
```bash
# Check HPA status
kubectl get hpa -A
kubectl describe hpa <hpa-name> -n <namespace>

# Check metrics availability
kubectl top pods -n <namespace>
kubectl top nodes
```

**Common Causes**:

1. **Metrics Server Not Installed**
   ```bash
   # Install metrics server
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

2. **No Resource Limits/Requests**
   - HPA requires resource requests to calculate scaling
   - Add to deployment spec

3. **Target Metric Not Available**
   ```bash
   # Check available metrics
   kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
   
   # For custom metrics, check custom metrics API
   kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1"
   ```

---

## Network Issues

### SNAT Port Exhaustion (CRITICAL for 100k users!)

**Problem**: Connection timeouts, failed outbound connections

**Symptoms**:
- Intermittent 503 errors
- Connection refused to external APIs
- Timeout errors

**Diagnosis**:
```bash
# Check SNAT metrics in Azure Monitor
az monitor metrics list \
  --resource <load-balancer-id> \
  --metric "AllocatedSnatPorts" \
  --interval PT1M

# Check connection count per node
kubectl exec -it <pod-name> -- netstat -an | grep ESTABLISHED | wc -l
```

**Solutions**:

1. **Already Configured: Multiple Outbound IPs**
   - Our config uses 4 outbound IPs (64,000 ports each = 256,000 total)

2. **Implement Connection Pooling**
   ```python
   # Example: Python requests with connection pooling
   from requests.adapters import HTTPAdapter
   from requests.packages.urllib3.util.retry import Retry
   
   session = requests.Session()
   adapter = HTTPAdapter(pool_connections=100, pool_maxsize=100)
   session.mount('http://', adapter)
   session.mount('https://', adapter)
   ```

3. **Use Azure NAT Gateway** (if SNAT still an issue)
   ```bash
   # Create NAT Gateway
   az network nat gateway create \
     --resource-group <rg> \
     --name aks-nat-gateway \
     --location eastus \
     --public-ip-addresses <pip-id>
   
   # Associate with subnet
   az network vnet subnet update \
     --resource-group <rg> \
     --vnet-name <vnet> \
     --name <subnet> \
     --nat-gateway aks-nat-gateway
   ```

4. **Reduce External Calls**
   - Implement caching (Redis)
   - Batch API requests
   - Use webhooks instead of polling

### DNS Resolution Failures

**Problem**: Pods can't resolve DNS names

**Diagnosis**:
```bash
# Test DNS from pod
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Check CoreDNS configuration
kubectl get configmap coredns -n kube-system -o yaml
```

**Solutions**:

1. **CoreDNS Overloaded**
   ```bash
   # Scale CoreDNS
   kubectl scale deployment coredns -n kube-system --replicas=5
   
   # Or use node-local DNS cache
   kubectl apply -f https://k8s.io/examples/admin/dns/nodelocaldns.yaml
   ```

2. **Network Policy Blocking DNS**
   ```bash
   # Allow DNS traffic
   kubectl apply -f - <<EOF
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: allow-dns
     namespace: default
   spec:
     podSelector: {}
     policyTypes:
     - Egress
     egress:
     - to:
       - namespaceSelector:
           matchLabels:
             name: kube-system
       ports:
       - protocol: UDP
         port: 53
   EOF
   ```

### Pod-to-Pod Communication Failures

**Problem**: Pods can't communicate with each other

**Diagnosis**:
```bash
# Test connectivity between pods
kubectl run test-pod --image=busybox --rm -it --restart=Never -- \
  wget -O- http://<service-name>.<namespace>.svc.cluster.local

# Check network policies
kubectl get networkpolicies -A

# Check service endpoints
kubectl get endpoints -n <namespace>
```

---

## Performance Problems

### High API Server Latency

**Problem**: kubectl commands are slow, API server timeouts

**Diagnosis**:
```bash
# Check API server metrics
kubectl get --raw /metrics | grep apiserver_request_duration

# Check control plane logs
az aks show --resource-group <rg> --name <cluster> \
  --query "diagnosticsProfile"
```

**Solutions**:

1. **Upgrade to Premium SKU**
   ```hcl
   # In variables.tf
   sku_tier = "Premium"  # 99.95% SLA vs 99.5%
   ```

2. **Reduce Watch/List Operations**
   - Limit number of controllers
   - Use field selectors
   - Implement caching in applications

3. **Increase API Server Capacity**
   - Premium tier automatically scales control plane

### Slow Pod Startup Times

**Problem**: Pods take minutes to start

**Diagnosis**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Common delays:
# - Image pull: Check "Pulling image" time
# - Scheduling: Check "Scheduled" event time
# - Init containers: Check init container logs
```

**Solutions**:

1. **Slow Image Pulls**
   ```bash
   # Use ACR with geo-replication (already configured)
   # Enable image caching on nodes
   
   # Pre-pull critical images via DaemonSet
   kubectl apply -f - <<EOF
   apiVersion: apps/v1
   kind: DaemonSet
   metadata:
     name: image-prepull
   spec:
     selector:
       matchLabels:
         name: image-prepull
     template:
       metadata:
         labels:
           name: image-prepull
       spec:
         containers:
         - name: prepull
           image: your-acr.azurecr.io/your-app:latest
           command: ["sleep", "infinity"]
   EOF
   ```

2. **Scheduling Delays**
   ```bash
   # Check scheduler logs
   kubectl logs -n kube-system -l component=kube-scheduler
   
   # Ensure nodes have capacity
   kubectl describe nodes | grep -A 5 "Allocated resources"
   ```

### High Node CPU/Memory Usage

**Problem**: Nodes consistently at 80%+ utilization

**Diagnosis**:
```bash
# Top resource consumers
kubectl top nodes
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory

# Check for resource-intensive processes
kubectl exec -it <pod-name> -- top
```

**Solutions**:

1. **Scale Node Pool**
   ```bash
   # Temporary manual scale
   az aks nodepool scale \
     --resource-group <rg> \
     --cluster-name <cluster> \
     --name userpool1 \
     --node-count 100
   ```

2. **Optimize Application Resource Usage**
   - Profile application
   - Reduce memory footprint
   - Implement caching
   - Optimize database queries

3. **Add Resource Limits**
   ```yaml
   resources:
     limits:
       cpu: 500m
       memory: 512Mi
   ```

---

## Pod Scheduling Failures

### Pods Stuck in Pending

**Problem**: Pods won't schedule despite available nodes

**Diagnosis**:
```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Look for scheduling events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

**Common Causes**:

1. **Insufficient Resources**
   ```
   Event: FailedScheduling ... Insufficient cpu/memory
   
   Solution: Either:
   - Reduce resource requests
   - Scale node pool
   - Add nodes manually
   ```

2. **Node Affinity Mismatch**
   ```bash
   # Check node labels
   kubectl get nodes --show-labels
   
   # Check pod affinity rules
   kubectl get pod <pod-name> -o yaml | grep -A 10 affinity
   ```

3. **Taints and Tolerations**
   ```bash
   # Check node taints
   kubectl describe nodes | grep -i taint
   
   # Add toleration to pod
   tolerations:
   - key: "high-performance"
     operator: "Equal"
     value: "true"
     effect: "NoSchedule"
   ```

4. **PVC Not Available**
   ```bash
   # Check PVC status
   kubectl get pvc -n <namespace>
   
   # Check PV availability
   kubectl get pv
   ```

---

## Resource Exhaustion

### Disk Pressure on Nodes

**Problem**: Nodes showing DiskPressure condition

**Diagnosis**:
```bash
# Check node conditions
kubectl describe node <node-name> | grep -A 10 Conditions

# Check disk usage
kubectl exec -n <namespace> <pod-name> -- df -h
```

**Solutions**:

1. **Clean Up Unused Images**
   ```bash
   # Set kubelet garbage collection
   # Already configured in node pools with proper thresholds
   
   # Manual cleanup if needed
   az aks nodepool upgrade \
     --resource-group <rg> \
     --cluster-name <cluster> \
     --name <nodepool> \
     --kubernetes-version <current-version>
   ```

2. **Increase Node Disk Size**
   ```hcl
   # In main.tf
   os_disk_size_gb = 512  # Increase from 256
   ```

### Memory Pressure / OOMKilled Pods

**Problem**: Pods being killed due to Out of Memory

**Diagnosis**:
```bash
# Check for OOM killed pods
kubectl get pods -A | grep OOMKilled

# Check pod logs before crash
kubectl logs <pod-name> --previous

# Check events
kubectl get events -A | grep -i "OOM"
```

**Solutions**:

1. **Increase Memory Limits**
   ```yaml
   resources:
     limits:
       memory: 1Gi  # Increase based on actual usage
   ```

2. **Fix Memory Leaks**
   - Profile application
   - Check for unbounded caches
   - Review connection pooling

3. **Use Larger Nodes**
   ```hcl
   user_node_vm_size = "Standard_D16s_v5"  # 64GB RAM
   ```

---

## Application Issues

### High Error Rates

**Problem**: Applications returning 500/503 errors

**Diagnosis**:
```bash
# Check application logs
kubectl logs -n <namespace> <pod-name> --tail=100

# Check ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Check service endpoints
kubectl get endpoints -n <namespace>
```

**Solutions**:

1. **Database Connection Pool Exhausted**
   ```python
   # Increase pool size
   DATABASE_POOL_SIZE=100
   DATABASE_MAX_OVERFLOW=50
   ```

2. **Application Overloaded**
   ```bash
   # Scale deployment
   kubectl scale deployment <deployment> -n <namespace> --replicas=50
   
   # Verify HPA is configured
   kubectl get hpa -n <namespace>
   ```

3. **Dependency Service Down**
   ```bash
   # Check all services
   kubectl get svc -A
   
   # Test connectivity
   kubectl run debug --rm -it --image=nicolaka/netshoot -- \
     curl http://<service-name>.<namespace>:80
   ```

---

## Monitoring & Observability

### Missing Metrics

**Problem**: Can't see pod/node metrics in kubectl top or Azure Monitor

**Solutions**:

1. **Install Metrics Server** (if not already)
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

2. **Verify Azure Monitor Integration**
   ```bash
   # Check if oms-agent is running
   kubectl get pods -n kube-system -l component=oms-agent
   
   # Check logs
   kubectl logs -n kube-system -l component=oms-agent
   ```

3. **Check Log Analytics Workspace**
   ```bash
   az monitor log-analytics workspace show \
     --resource-group <rg> \
     --workspace-name <workspace>
   ```

### High Azure Monitor Costs

**Problem**: Log Analytics costs are very high

**Solutions**:

1. **Reduce Log Collection**
   ```bash
   # Update OMS agent config
   kubectl edit configmap container-azm-ms-agentconfig -n kube-system
   
   # Exclude certain namespaces
   # Reduce collection frequency
   ```

2. **Set Data Retention**
   ```bash
   az monitor log-analytics workspace update \
     --resource-group <rg> \
     --workspace-name <workspace> \
     --retention-time 30  # Reduce from 90 days
   ```

---

## Emergency Procedures

### Complete Cluster Outage

1. **Check Azure Service Health**
   ```bash
   az rest --method get \
     --url "https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.ResourceHealth/events?api-version=2022-10-01"
   ```

2. **Verify Cluster State**
   ```bash
   az aks show --resource-group <rg> --name <cluster> --query powerState
   ```

3. **Check Control Plane**
   ```bash
   kubectl get cs  # Component status
   kubectl get nodes
   ```

4. **Contact Azure Support**
   - Open High Severity ticket
   - Provide cluster details and error messages

### Data Loss Prevention

```bash
# Regular backups
# 1. Backup etcd (automatic with AKS)
# 2. Backup application data
velero backup create full-backup --include-namespaces production

# 3. Export cluster state
kubectl get all --all-namespaces -o yaml > cluster-state.yaml

# 4. Backup Terraform state (automated in Makefile)
make backup-state
```

---

## Getting Help

1. **Azure Support**: For infrastructure/platform issues
2. **Application Logs**: Check pod logs first
3. **Cluster Events**: kubectl get events -A
4. **Community**: AKS GitHub issues, Stack Overflow
5. **This Team**: Slack #aks-support channel
