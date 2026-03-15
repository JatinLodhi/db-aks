# Azure Monitor Alert Rules for AKS High-Scale Cluster
# These can be created via Azure Portal, Azure CLI, or Terraform

# 1. Node CPU Utilization Alert
# Alert when average node CPU exceeds 80% for 10 minutes
az monitor metrics alert create \
  --name "AKS-Node-High-CPU" \
  --resource-group "aks-production-rg" \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/Microsoft.ContainerService/managedClusters/aks-prod-cluster" \
  --condition "avg node_cpu_usage_percentage > 80" \
  --window-size 10m \
  --evaluation-frequency 5m \
  --action-group-ids "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/microsoft.insights/actionGroups/ops-team" \
  --severity 2 \
  --description "Node CPU usage is consistently high"

# 2. Node Memory Utilization Alert
az monitor metrics alert create \
  --name "AKS-Node-High-Memory" \
  --resource-group "aks-production-rg" \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/Microsoft.ContainerService/managedClusters/aks-prod-cluster" \
  --condition "avg node_memory_working_set_percentage > 85" \
  --window-size 10m \
  --evaluation-frequency 5m \
  --action-group-ids "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/microsoft.insights/actionGroups/ops-team" \
  --severity 2

# 3. Pod Restart Alert
az monitor metrics alert create \
  --name "AKS-High-Pod-Restarts" \
  --resource-group "aks-production-rg" \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/Microsoft.ContainerService/managedClusters/aks-prod-cluster" \
  --condition "avg restart_count > 5" \
  --window-size 15m \
  --evaluation-frequency 5m \
  --action-group-ids "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/microsoft.insights/actionGroups/ops-team" \
  --severity 3

# 4. Cluster Autoscaler Alert - Max Nodes Reached
az monitor metrics alert create \
  --name "AKS-Max-Nodes-Reached" \
  --resource-group "aks-production-rg" \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/Microsoft.ContainerService/managedClusters/aks-prod-cluster" \
  --condition "avg node_count >= 300" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action-group-ids "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/microsoft.insights/actionGroups/ops-team" \
  --severity 1 \
  --description "Cluster is at or near maximum node count"

# 5. SNAT Port Exhaustion Alert (Critical for high concurrency)
az monitor metrics alert create \
  --name "AKS-SNAT-Port-Exhaustion" \
  --resource-group "aks-production-rg" \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/Microsoft.ContainerService/managedClusters/aks-prod-cluster" \
  --condition "avg allocatedSnatPorts > 50000" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action-group-ids "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/microsoft.insights/actionGroups/ops-team" \
  --severity 1

# 6. API Server Latency Alert
az monitor metrics alert create \
  --name "AKS-API-Server-Latency" \
  --resource-group "aks-production-rg" \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/Microsoft.ContainerService/managedClusters/aks-prod-cluster" \
  --condition "avg apiserver_request_duration_milliseconds > 1000" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action-group-ids "/subscriptions/{subscription-id}/resourceGroups/aks-production-rg/providers/microsoft.insights/actionGroups/ops-team" \
  --severity 2

---

# Azure Monitor Workbook Query Examples
# Use these in Azure Monitor Workbooks for custom dashboards

# 1. Top 10 Pods by CPU Usage
KubePodInventory
| where TimeGenerated > ago(1h)
| summarize AvgCPU = avg(PodCpuUsagePercent) by Name
| top 10 by AvgCPU desc

# 2. Top 10 Pods by Memory Usage
KubePodInventory
| where TimeGenerated > ago(1h)
| summarize AvgMemory = avg(PodMemoryWorkingSetBytes) by Name
| extend AvgMemoryMB = AvgMemory / 1024 / 1024
| top 10 by AvgMemoryMB desc

# 3. Pod Restart Events
KubePodInventory
| where TimeGenerated > ago(24h)
| where PodRestartCount > 0
| summarize RestartCount = sum(PodRestartCount) by Name, Namespace
| order by RestartCount desc

# 4. Node Resource Utilization Over Time
KubeNodeInventory
| where TimeGenerated > ago(6h)
| summarize AvgCPU = avg(NodeCpuUsagePercent), AvgMemory = avg(NodeMemoryWorkingSetPercent) by bin(TimeGenerated, 5m), NodeName
| render timechart

# 5. Cluster Autoscaler Events
AzureDiagnostics
| where Category == "cluster-autoscaler"
| where TimeGenerated > ago(24h)
| project TimeGenerated, OperationName, ResultDescription
| order by TimeGenerated desc

# 6. Failed Pod Scheduling
KubeEvents
| where TimeGenerated > ago(1h)
| where Reason == "FailedScheduling"
| project TimeGenerated, Message, Name, Namespace
| order by TimeGenerated desc

# 7. Network Traffic Analysis
NetworkMonitoring
| where TimeGenerated > ago(1h)
| summarize TotalBytes = sum(BytesReceived + BytesSent) by bin(TimeGenerated, 5m)
| render timechart

# 8. Container Image Pull Errors
ContainerInventory
| where TimeGenerated > ago(24h)
| where ImagePullStatus == "Failed"
| summarize Count = count() by Image, ImagePullStatus
| order by Count desc

---

# Prometheus/Grafana Configuration (if using)
# Install Prometheus Operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi

# Key Metrics to Monitor:
# - container_cpu_usage_seconds_total
# - container_memory_working_set_bytes
# - kubelet_running_pods
# - apiserver_request_duration_seconds
# - scheduler_pending_pods
# - node_network_transmit_bytes_total
# - node_network_receive_bytes_total

---

# Log Analytics Queries for Troubleshooting

# 1. Identify Memory OOM Kills
ContainerLog
| where TimeGenerated > ago(24h)
| where LogEntry contains "OOMKilled" or LogEntry contains "Out of memory"
| project TimeGenerated, Name, Namespace, LogEntry

# 2. Find Pods with High Error Rates
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "ERROR" or LogEntry contains "FATAL"
| summarize ErrorCount = count() by Name, Namespace
| order by ErrorCount desc

# 3. Network Connection Errors
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "connection refused" or LogEntry contains "timeout"
| project TimeGenerated, Name, Namespace, LogEntry
| order by TimeGenerated desc

# 4. SSL/TLS Certificate Issues
ContainerLog
| where TimeGenerated > ago(24h)
| where LogEntry contains "certificate" or LogEntry contains "SSL" or LogEntry contains "TLS"
| project TimeGenerated, Name, Namespace, LogEntry

---

# Recommended Alerting Thresholds for 100k Concurrent Users:

# Critical (Severity 1 - Page On-Call):
# - API server latency > 2 seconds (5 min window)
# - Node failure > 10% of cluster
# - SNAT port exhaustion > 80%
# - Max nodes reached (300 nodes)
# - Multiple pod crash loops (>10 pods)

# Warning (Severity 2 - Ticket + Notification):
# - Node CPU > 80% (10 min window)
# - Node Memory > 85% (10 min window)
# - Pod restart count > 5 (15 min window)
# - API server latency > 1 second
# - Pending pods > 50 (5 min window)

# Info (Severity 3 - Ticket Only):
# - Node CPU > 70% (15 min window)
# - Node Memory > 75% (15 min window)
# - Cluster scaling events
# - Image pull failures

---

# Create Action Group (for alert notifications)
az monitor action-group create \
  --name "ops-team" \
  --resource-group "aks-production-rg" \
  --short-name "opstm" \
  --email-receiver name="ops-email" email="ops@company.com" \
  --sms-receiver name="ops-sms" country-code="1" phone-number="5551234567" \
  --webhook-receiver name="slack-webhook" service-uri="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
