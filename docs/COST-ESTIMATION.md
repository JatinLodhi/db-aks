# Azure AKS Infrastructure Cost Estimation

**Generated:** March 17, 2026  
**Instance Type:** Standard_D4s_v5 (4 vCPU, 16GB RAM)  
**Region:** East US  
**Currency:** USD  
**Use Case:** 3-Day Event Setup

---

## Executive Summary

This document provides detailed cost estimates for a 3-day event using Azure Kubernetes Service (AKS). The setup is optimized for cost-efficiency with Standard SSD disks, Basic container registry, and a single event environment.

### Cost Overview

| Configuration | 3-Day Cost | Monthly Cost |
|---------------|------------|--------------|
| **Base (7 nodes)** | **$145.73** | **$1,457.20** |
| **Average (11 nodes)** | **$212.77** | **$2,127.60** |
| **Peak (15 nodes)** | **$279.81** | **$2,798.00** |

### Hourly Rates

| Configuration | Cost per Hour |
|---------------|---------------|
| Base (7 nodes) | $2.02/hr |
| Average (11 nodes) | $2.95/hr |
| Peak (15 nodes) | $3.88/hr |

**Event-Optimized Configuration:**
- Duration: 3 days (72 hours)
- Standard SSD disks (cost-effective)
- Basic ACR tier (single registry, no geo-replication)
- Single environment (no dev/prod separation)
- Recommended budget: **$300** (covers peak with buffer)

---

## 1. Cost Breakdown by Component

### 1.1 AKS Cluster Management

| Component | SKU/Tier | Monthly Cost | 3-Day Cost | Notes |
|-----------|----------|--------------|------------|-------|
| AKS Control Plane | Standard | $73.00 | $7.30 | 99.5% uptime SLA |

**Cost Calculation:**
- 3-Day Cost = (Monthly Cost / 30 days) × 3 days
- $73.00 / 30 × 3 = **$7.30**

**Notes:**
- Standard tier provides 99.5% uptime SLA
- Sufficient for event workloads
- Free tier available but no SLA guarantee

---

### 1.2 Compute Resources (Virtual Machines)

**VM Specifications: Standard_D4s_v5**
- vCPUs: 4
- RAM: 16 GB
- Temporary Storage: 150 GB SSD
- Monthly Cost: $158.00 per VM
- **Hourly Cost: $0.219 per VM**
- **3-Day Cost: $15.77 per VM**

#### Event Configuration

| Node Pool | VM Size | Nodes | Hourly Cost | Monthly Cost | 3-Day Cost |
|-----------|---------|-------|-------------|--------------|------------|
| System Pool | Standard_D4s_v5 | 3 | $0.657/hr | $474.00 | $47.40 |
| Frontend Pool | Standard_D4s_v5 | 2 | $0.438/hr | $316.00 | $31.60 |
| Backend Pool | Standard_D4s_v5 | 2 | $0.438/hr | $316.00 | $31.60 |
| **Total (Base - 7 nodes)** | | **7** | **$1.533/hr** | **$1,106.00** | **$110.60** |
| **Total (Average - 11 nodes)** | | **11** | **$2.409/hr** | **$1,738.00** | **$173.80** |
| **Total (Peak - 15 nodes)** | | **15** | **$3.285/hr** | **$2,370.00** | **$237.00** |

**3-Day Event Calculation:**
- Base (7 nodes): $1,106.00 / 30 × 3 = **$110.60**
- Average (11 nodes): $1,738.00 / 30 × 3 = **$173.80**
- Peak (15 nodes): $2,370.00 / 30 × 3 = **$237.00**

**Autoscaling Configuration:**
- **System Pool:** Min: 3, Max: 5
- **Frontend Pool:** Min: 2, Max: 8
- **Backend Pool:** Min: 2, Max: 7
- **Peak Capacity:** 20 nodes maximum

---

### 1.3 Storage Costs

#### OS Disks (Standard SSD)

| Component | Type | Size | Monthly Cost | 3-Day Cost | Quantity | Total (Monthly) | Total (3-Day) |
|-----------|------|------|--------------|------------|----------|-----------------|---------------|
| OS Disk (per node) | E10 Standard SSD | 128 GB | $9.60 | $0.96 | Based on nodes | Variable | Variable |

**Cost by Configuration:**

| Scenario | Nodes | Monthly Cost | 3-Day Cost |
|----------|-------|--------------|------------|
| **Base** | 7 | $67.20 | $6.72 |
| **Average** | 11 | $105.60 | $10.56 |
| **Peak** | 15 | $144.00 | $14.40 |

**Cost Comparison: Standard SSD vs Premium SSD**

| Disk Type | Size | Monthly Cost/Disk | 3-Day Cost/Disk | Savings |
|-----------|------|-------------------|-----------------|---------|
| Premium SSD (P10) | 128 GB | $19.71 | $1.97 | - |
| **Standard SSD (E10)** | **128 GB** | **$9.60** | **$0.96** | **51%** |

**Benefits of Standard SSD:**
- 51% cost savings vs Premium SSD
- Sufficient IOPS (500) for most workloads
- Good for event workloads without extreme I/O requirements
- ~$10/month per disk savings

#### Additional Storage (Optional)

| Component | Type | Monthly Cost | 3-Day Cost | Notes |
|-----------|------|--------------|------------|-------|
| Persistent Volume Claims | Standard SSD | $9.60/100GB | $0.96/100GB | As needed |
| Container Image Storage | Included in ACR | $0.00 | $0.00 | Up to 10 GB |

---

### 1.4 Networking Costs

| Component | Type | Monthly Cost | 3-Day Cost | Notes |
|-----------|------|--------------|------------|-------|
| Load Balancer (Standard) | Standard | $18.75 | $1.88 | Required for AKS |
| Load Balancer Rules | Rule processing | $8.00 | $0.80 | 10 rules |
| Public IP Address | Static | $3.65 | $0.37 | 1 IP |
| Outbound Data Transfer | First 5 GB free | $0.00 | $0.00 | 3-day event <5GB |
| **Total** | | **$30.40** | **$3.05** | |

**3-Day Event Data Transfer Estimate:**
- Estimated traffic: 2-4 GB for 3-day event
- First 5 GB/month: **Free**
- No additional data transfer charges expected

---

### 1.5 Container Registry (ACR)

| Component | SKU | Storage | Monthly Cost | 3-Day Cost | Notes |
|-----------|-----|---------|--------------|------------|-------|
| Registry | **Basic** | 10 GB included | $15.00 | $1.50 | Cost-effective |
| Additional Storage | Over 10 GB | $0.033/GB-day | - | - | Unlikely for events |
| **Total** | | | **$15.00** | **$1.50** | |

**Basic Tier Features:**
- 10 GB storage included (sufficient for most events)
- Unlimited image pulls
- Webhooks for CI/CD
- Geo-replication: Not included (not needed for short events)
- Vulnerability scanning: Not included

**Cost Comparison:**

| Tier | Monthly Cost | 3-Day Cost | Storage | Geo-Replication | Best For |
|------|--------------|------------|---------|-----------------|----------|
| **Basic** | **$15.00** | **$1.50** | **10 GB** | **No** | **Events/Dev** |
| Standard | $60.00 | $6.00 | 100 GB | No | Regular workloads |
| Premium | $168.00 | $16.80 | 500 GB | Yes | Enterprise production |

**Savings: $321/month** (95% reduction from Premium with geo-replication)

---

### 1.6 Monitoring & Logging

| Component | Service | Monthly Cost | 3-Day Cost | Ingestion | Notes |
|-----------|---------|--------------|------------|-----------|-------|
| Log Analytics Workspace | Per GB | $165.60 | $16.56 | 2 GB/day | Event monitoring |
| Data Retention (30 days) | First 31 days | $0.00 | $0.00 | Included | Free retention |
| Container Insights | Data collection | Included | Included | Included | Built-in |
| **Total** | | **$165.60** | **$16.56** | | |

**3-Day Event Log Estimates:**
- Total logs for 3 days: ~6 GB
- Average: 2 GB/day
- Cost per GB: $2.76
- Monthly equivalent: 2 GB/day × 30 days = 60 GB = $165.60
- **3-Day cost: 6 GB × $2.76 = $16.56**

**Log Volume Breakdown:**
- Cluster metrics: ~0.5 GB/day
- Container logs: ~1 GB/day
- Application logs: ~0.5 GB/day
- Total: ~2 GB/day (reduced for event scenario)

---

### 1.7 Additional Resources

| Component | Type | Monthly Cost | 3-Day Cost | Notes |
|-----------|------|--------------|------------|-------|
| Virtual Network | Free | $0.00 | $0.00 | No charge |
| Subnets | Free | $0.00 | $0.00 | No charge |
| Managed Identity | Free | $0.00 | $0.00 | No charge |
| Network Security Groups | Free | $0.00 | $0.00 | No charge |
| Application Gateway | Not used | $0.00 | $0.00 | Not needed for event |

---

## 2. Total Cost Estimates

### 2.1 Three-Day Event Costs

| Component | Base (7 nodes) | Average (11 nodes) | Peak (15 nodes) |
|-----------|----------------|--------------------|-----------------|
| AKS Control Plane | $7.30 | $7.30 | $7.30 |
| Compute (VMs) | $110.60 | $173.80 | $237.00 |
| Storage (Standard SSD) | $6.72 | $10.56 | $14.40 |
| Networking | $3.05 | $3.05 | $3.05 |
| Container Registry (Basic) | $1.50 | $1.50 | $1.50 |
| Monitoring | $16.56 | $16.56 | $16.56 |
| **3-Day Total** | **$145.73** | **$212.77** | **$279.81** |

### 2.2 Monthly Cost Projection (if sustained)

| Component | Base (7 nodes) | Average (11 nodes) | Peak (15 nodes) |
|-----------|----------------|--------------------|-----------------|
| AKS Control Plane | $73.00 | $73.00 | $73.00 |
| Compute (VMs) | $1,106.00 | $1,738.00 | $2,370.00 |
| Storage (Standard SSD) | $67.20 | $105.60 | $144.00 |
| Networking | $30.40 | $30.40 | $30.40 |
| Container Registry (Basic) | $15.00 | $15.00 | $15.00 |
| Monitoring | $165.60 | $165.60 | $165.60 |
| **Monthly Total** | **$1,457.20** | **$2,127.60** | **$2,798.00** |

### 2.3 Hourly Cost Breakdown

| Component | Base (7 nodes) | Average (11 nodes) | Peak (15 nodes) |
|-----------|----------------|--------------------|--------------------|
| Compute | $1.533/hr | $2.409/hr | $3.285/hr |
| Storage | $0.093/hr | $0.146/hr | $0.200/hr |
| Networking | $0.042/hr | $0.042/hr | $0.042/hr |
| Other | $0.354/hr | $0.354/hr | $0.354/hr |
| **Total per Hour** | **$2.022/hr** | **$2.951/hr** | **$3.881/hr** |

**72-Hour Event Calculation:**
- Base: $2.022/hr × 72 hours = **$145.58**
- Average: $2.951/hr × 72 hours = **$212.47**  
- Peak: $3.881/hr × 72 hours = **$279.43**

---

## 3. Cost Optimization Strategies Implemented

### 3.1 Standard SSD vs Premium SSD

**Decision: Standard SSD** ✓

| Metric | Standard SSD | Premium SSD | Savings |
|--------|--------------|-------------|---------|
| Cost per disk | $9.60/month | $19.71/month | **51%** |
| IOPS | 500 | 500 | Same |
| Throughput | 60 MB/s | 100 MB/s | Sufficient for event |
| **Monthly savings (7 nodes)** | | | **$70.77** |
| **3-Day savings (7 nodes)** | | | **$7.07** |

### 3.2 Container Registry Tier Selection

**Decision: Basic Tier** ✓

| Feature | Basic | Premium (with geo-rep) | Savings |
|---------|-------|------------------------|---------|
| Monthly Cost | $15.00 | $336.00 | **$321.00** |
| 3-Day Cost | $1.50 | $33.60 | **$32.10** |
| Storage | 10 GB | 1000 GB | Sufficient |
| Geo-Replication | No | Yes | Not needed for event |

**Result: 95% cost reduction on ACR**

### 3.3 Single Environment Setup

**Decision: One environment instead of separate dev/prod** ✓

| Aspect | Dual Environment | Single Event | Savings |
|--------|------------------|--------------|---------|
| AKS Control Planes | 2× | 1× | $73-292/month |
| Node Pools | Duplicated | Consolidated | ~50% |
| ACR Registries | 2× | 1× | $15-336/month |
| Monitoring | 2× | 1× | $165/month |

**Result: ~50% overall infrastructure savings**

### 3.4 Event-Optimized Scaling

**Strategy: Right-sized for 3-day duration**

- No reserved instances (short duration doesn't justify commitment)
- Autoscaling configured for event traffic patterns
- Monitoring reduced to essential metrics only
- No unnecessary redundancy (appropriate for short-term event)

### 3.5 Cost Savings Summary

| Optimization | Monthly Savings | 3-Day Savings | Impact |
|--------------|-----------------|---------------|--------|
| Standard SSD vs Premium | $70.77 | $7.07 | 51% on storage |
| Basic ACR vs Premium | $321.00 | $32.10 | 95% on registry |
| Single environment | ~$1,200 | ~$120 | ~50% overall |
| Event-optimized config | $300+ | $30+ | 15-20% |
| **Total Optimizations** | **~$1,891** | **~$189** | **56% reduction** |

**Before Optimization:** ~$5,200/month for dual premium setup  
**After Optimization:** ~$2,128/month for event-optimized setup  
**Net Savings: 59%**

---

## 4. Event Scenario Breakdown

### 4.1 3-Day Event Timeline

| Time Period | Node Count | Hourly Cost | Period Cost | Use Case |
|-------------|------------|-------------|-------------|----------|
| **Pre-Event (4 hours)** | 7 (base) | $2.022 | $8.09 | Setup & testing |
| **Day 1 (24 hours)** | 11 (average) | $2.951 | $70.82 | Ramp-up traffic |
| **Day 2 (24 hours)** | 15 (peak) | $3.881 | $93.14 | Peak traffic |
| **Day 3 (20 hours)** | 11 (average) | $2.951 | $59.02 | Wind-down |
| **Post-Event (4 hours)** | 7 (base) | $2.022 | $8.09 | Cleanup |
| **Total (76 hours)** | | | **$239.16** | Full event |

### 4.2 Traffic Pattern Scenarios

| Scenario | Description | Nodes | 3-Day Cost | Monthly Equivalent |
|----------|-------------|-------|------------|-------------------|
| **Conservative** | Low traffic, minimal scaling | 7-9 | $145-170 | $1,457-1,700 |
| **Expected** | Normal event traffic | 7-15 | $213 | $2,128 |
| **Aggressive** | High traffic, frequent scaling | 10-20 | $300 | $3,000 |
| **Maximum** | Sustained peak load | 15-20 | $350 | $3,500 |

### 4.3 Cost by Event Phase

**Setup Phase (Day 0):**
- Duration: 4-8 hours
- Nodes: 7 (base)
- Cost: $8-16
- Activities: Deployment, testing, warm-up

**Active Event (Days 1-3):**
- Duration: 68 hours
- Nodes: 7-15 (dynamic)
- Cost: $197-264
- Activities: Serving traffic, monitoring, scaling

**Teardown (Day 4):**
- Duration: 4 hours
- Nodes: 7 (base)
- Cost: $8
- Activities: Backup, cleanup, resource deallocation

**Total Event Cycle: $213-288** (includes full lifecycle)

---

## 5. Cost Monitoring & Alerts

### 5.1 Recommended Budget for 3-Day Event

| Alert Level | Threshold | Amount | Action |
|-------------|-----------|--------|--------|
| Warning | 75% of budget | $225 | Review scaling |
| Critical | 100% of budget | $300 | Investigate anomalies |
| Emergency | 150% of budget | $450 | Immediate review |

**Recommended Budget: $300** (covers up to peak scenario with buffer)

### 5.2 Real-Time Cost Monitoring

**Key Metrics to Watch:**

| Metric | Normal Range | Alert Threshold | Frequency |
|--------|--------------|-----------------|-----------|
| Active nodes | 7-15 | >18 nodes | Every 15 min |
| Hourly cost | $2-4/hr | >$5/hr | Continuous |
| Data egress | <2 GB/day | >5 GB/day | Hourly |
| Log ingestion | <2 GB/day | >3 GB/day | Every 6 hours |

### 5.3 Resource Tags for Cost Tracking

```terraform
tags = {
  Environment = "Event"
  EventName   = "3-Day-Launch"
  CostCenter  = "Marketing"
  Owner       = "Event-Team"
  Duration    = "Temporary"
  AutoShutdown = "Enabled"
}
```

### 5.4 Post-Event Cost Verification Checklist

- [ ] Verify all temporary resources deleted
- [ ] Confirm node pools scaled down or deleted
- [ ] Review final cost report in Azure Cost Management
- [ ] Export cost data for event ROI analysis
- [ ] Document actual vs. estimated costs
- [ ] Archive logs before workspace cleanup

---

## 6. Additional Optimization Options

### 6.1 Spot Virtual Machines (High Risk for Events)

**Not Recommended for Critical Events** ⚠️

| Configuration | Standard Cost | Spot Cost | Savings | Risk Level |
|---------------|---------------|-----------|---------|------------|
| Event workload | $158.00/node | ~$31.60/node | 80% | **HIGH** |

**Why Not Recommended:**
- Spot VMs can be evicted with 30 seconds notice
- Unpredictable availability during events
- Could cause service disruptions at critical moments
- Better suited for batch jobs or dev environments

**Exception:** Could use Spot VMs for non-critical backend processing

### 6.2 Alternative VM Sizes

| VM Size | vCPU | RAM | Monthly Cost | 3-Day Cost | Use Case |
|---------|------|-----|--------------|------------|----------|
| Standard_D2s_v5 | 2 | 8 GB | $79.00 | $7.90 | Light workloads |
| **Standard_D4s_v5** | **4** | **16 GB** | **$158.00** | **$15.80** | **Balanced (current)** |
| Standard_F4s_v2 | 4 | 8 GB | $142.00 | $14.20 | CPU-optimized |
| Standard_D8s_v5 | 8 | 32 GB | $316.00 | $31.60 | Memory-intensive |

**Standard_F4s_v2 Alternative:**
- 10% cheaper ($16/node/month savings)
- Better CPU performance
- Half the RAM (8 GB vs 16 GB)
- Good for CPU-bound, memory-light workloads

**Potential 3-Day Savings with F4s_v2:** ~$11 (for 7 nodes)

### 6.3 Infrastructure as Code Benefits

**Current Setup (Terraform):**
- ✓ Rapid deployment (< 1 hour)
- ✓ Consistent configuration
- ✓ Easy teardown after event
- ✓ Version controlled infrastructure
- ✓ Reusable for future events

**Cost Benefits:**
- No manual configuration errors
- Faster time-to-ready (saves operational costs)
- Easy to replicate for multiple events
- Automated cleanup prevents forgotten resources

---

## 7. Multiple Event Scenarios

### 7.1 Single vs Multiple Events

| Frequency | Cost per Event | Monthly Total |
|-----------|----------------|---------------|
| One-time event | $213 | $213 (once) |
| 2 events/month | $213 each | $426 |
| 4 events/month | $213 each | $852 |
| Weekly events | $213 each | $852-1,065 |

**Note:** Based on average configuration (11 nodes) per event

### 7.2 Event-Based vs Always-On

| Approach | 3-Day Cost | Monthly Cost | Best For |
|----------|------------|--------------|----------|
| **Event-Based (Current)** | $213 | $0 (when idle) | Infrequent events |
| **Always-On (7 nodes)** | Included | $1,457 | Daily usage |
| **Always-On (11 nodes)** | Included | $2,128 | Continuous usage |
| **Always-On (15 nodes)** | Included | $2,798 | High traffic |

**Break-Even Point:**
- Event-based is cheaper for **<7 events per month**
- For weekly+ events, consider always-on infrastructure
- Current setup optimized for occasional events

---

## 8. Pre-Event Checklist & Recommendations

### 8.1 Before Event Deployment

**Cost Preparation:**
- [ ] Set Azure budget alert for $300
- [ ] Enable cost anomaly detection
- [ ] Configure resource tags for event tracking
- [ ] Review and approve cost estimate with stakeholders
- [ ] Set up billing notifications to event team

**Infrastructure Preparation:**
- [ ] Test Terraform deployment in test subscription
- [ ] Validate autoscaling policies
- [ ] Configure monitoring dashboards
- [ ] Test application deployment process
- [ ] Prepare rollback procedures

**Cost Optimization:**
- [ ] Confirm Standard SSD disk selection
- [ ] Verify Basic ACR tier configuration
- [ ] Review node pool sizes (7-15 nodes)
- [ ] Set up automated shutdown post-event
- [ ] Document cleanup procedures

### 8.2 During Event

**Monitoring:**
- [ ] Track real-time costs in Azure Cost Management
- [ ] Monitor node scaling patterns
- [ ] Watch for cost anomalies (>$5/hour)
- [ ] Check log ingestion rates
- [ ] Verify autoscaling is working correctly

**Cost Controls:**
- [ ] Alert on unexpected node scale-up
- [ ] Monitor data egress costs
- [ ] Track storage consumption
- [ ] Review application performance metrics

### 8.3 After Event

**Immediate (Within 4 hours):**
- [ ] Scale down node pools to minimum
- [ ] Export logs and metrics for analysis
- [ ] Backup critical data
- [ ] Stop unnecessary services

**Within 24 hours:**
- [ ] Delete temporary resources
- [ ] Remove unused persistent volumes
- [ ] Clean up container images
- [ ] Verify all resources stopped/deleted

**Within 1 week:**
- [ ] Generate final cost report
- [ ] Compare actual vs. estimated costs
- [ ] Document lessons learned
- [ ] Archive event data
- [ ] Update cost model for future events

## 9. Cost Reference Guide

### 9.1 Quick Cost Summary

| Scenario | 3-Day Cost | Monthly Cost | Hourly Cost |
|----------|------------|--------------|-------------|
| **Minimum (7 nodes)** | $145.73 | $1,457.20 | $2.02/hr |
| **Recommended (11 nodes)** | $212.77 | $2,127.60 | $2.95/hr |
| **Peak (15 nodes)** | $279.81 | $2,798.00 | $3.88/hr |

### 9.2 Component Costs

| Component | Per Unit/Month | 3-Day Cost |
|-----------|----------------|------------|
| Standard_D4s_v5 VM | $158.00 | $15.80 |
| Standard SSD (128GB) | $9.60 | $0.96 |
| AKS Control Plane | $73.00 | $7.30 |
| Basic ACR | $15.00 | $1.50 |
| Load Balancer | $30.40 | $3.05 |
| Monitoring (2GB/day) | $165.60 | $16.56 |

### 9.3 Per-Node Cost

| Item | Monthly | 3-Day |
|------|---------|-------|
| VM (Standard_D4s_v5) | $158.00 | $15.80 |
| OS Disk (Standard SSD) | $9.60 | $0.96 |
| **Total per Node** | **$167.60** | **$16.76** |

### 9.4 Savings Achieved

| Optimization | Savings | Status |
|--------------|---------|--------|
| Standard SSD vs Premium | 51% on storage | ✓ |
| Basic ACR vs Premium | 95% on registry | ✓ |
| Single environment | ~50% overall | ✓ |
| Event-based (vs always-on) | Only pay when used | ✓ |

---

## 10. Appendix

### 10.1 Pricing Assumptions

- **Pricing Date:** March 2026
- **Region:** East US
- **Currency:** USD
- **Pricing Model:** Pay-as-you-go
- **Event Duration:** 72 hours (3 days)
- **Operating System:** Linux (Ubuntu)

### 10.2 Calculation Methodology

**3-Day Cost Formula:**
```
3-Day Cost = (Monthly Cost ÷ 30 days) × 3 days
```

**Hourly Cost Formula:**
```
Hourly Cost = Monthly Cost ÷ 730 hours
```

**Total Event Cost:**
```
Total = (Compute + Storage + Networking + ACR + Monitoring + Control Plane) × (3/30)
```

### 10.3 Important Disclaimers

1. **Price Variability:** Azure prices may change; verify current pricing before deployment
2. **Data Transfer:** Actual costs depend on usage patterns; estimate assumes <5 GB (free tier)
3. **Event Duration:** Costs calculated for 72 hours; actual may vary based on setup/teardown time
4. **Autoscaling:** Actual node count depends on workload; estimates use average scenarios
5. **Regional Differences:** East US pricing; other regions may differ by 5-15%
6. **Hidden Costs:** Does not include: DNS, application-specific resources, third-party services

### 10.4 Cost Monitoring Tools

**Built-in Azure Tools:**
- **Azure Cost Management** - Real-time cost tracking
- **Azure Advisor** - Cost optimization recommendations
- **Azure Monitor** - Resource usage metrics
- **Azure Pricing Calculator** - Pre-deployment estimates

**Kubernetes Tools:**
- **kubectl top** - Node/pod resource usage
- **Kubecost** - Kubernetes-specific cost allocation
- **Prometheus + Grafana** - Custom cost dashboards

### 10.5 Additional Resources

**Azure Documentation:**
- [AKS Pricing](https://azure.microsoft.com/pricing/details/kubernetes-service/)
- [VM Pricing](https://azure.microsoft.com/pricing/details/virtual-machines/linux/)
- [Storage Pricing](https://azure.microsoft.com/pricing/details/managed-disks/)
- [ACR Pricing](https://azure.microsoft.com/pricing/details/container-registry/)
- [Monitor Pricing](https://azure.microsoft.com/pricing/details/monitor/)

**Cost Management:**
- [Azure Cost Management Best Practices](https://learn.microsoft.com/azure/cost-management-billing/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure TCO Calculator](https://azure.microsoft.com/pricing/tco/calculator/)

### 10.6 Terraform Configuration for Events

**Recommended terraform.tfvars for 3-day event:**

```hcl
# Event Configuration
environment         = "event"
cluster_name        = "aks-event-cluster"
resource_group_name = "aks-event-rg"

# Cost Optimization
sku_tier                     = "Standard"  # vs Premium
system_node_vm_size          = "Standard_D4s_v5"
create_acr                   = true
acr_sku                      = "Basic"     # vs Premium
acr_geo_replication_location = null        # Disabled

# Node Pools - Event Optimized
system_node_count     = 3
system_node_min_count = 3
system_node_max_count = 5

frontend_node_initial_count = 2
frontend_node_min_count     = 2
frontend_node_max_count     = 8

backend_node_initial_count = 2
backend_node_min_count     = 2
backend_node_max_count     = 7

# Monitoring (reduced for short event)
log_retention_days = 7  # vs 30 days

# Tags for cost tracking
tags = {
  Environment = "Event"
  Duration    = "3-days"
  CostCenter  = "Marketing"
  AutoCleanup = "Enabled"
  Budget      = "300-USD"
}
```

### 10.7 Post-Event Cleanup Script

**Save costs by ensuring complete cleanup:**

```bash
#!/bin/bash
# Post-event cleanup script

echo "🧹 Starting cleanup for 3-day event..."

# Delete resource group (removes all resources)
az group delete --name aks-event-rg --yes --no-wait

echo "✓ Deletion initiated"
echo "⏳ Resources will be cleaned up in 5-10 minutes"

# Verify deletion (run after 10 minutes)
sleep 600
az group show --name aks-event-rg 2>/dev/null || echo "✓ All resources cleaned up successfully"

# Cost verification (run 24 hours after cleanup)
echo "📊 Checking final costs..."
az consumption usage list \
  --start-date $(date -d '3 days ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?contains(instanceId, 'aks-event')].{Resource:instanceName, Cost:pretaxCost}"
```

**PowerShell version:**

```powershell
# Post-event cleanup script

Write-Host "🧹 Starting cleanup for 3-day event..." -ForegroundColor Green

# Delete resource group (removes all resources)
az group delete --name aks-event-rg --yes --no-wait

Write-Host "✓ Deletion initiated" -ForegroundColor Green
Write-Host "⏳ Resources will be cleaned up in 5-10 minutes" -ForegroundColor Yellow

# Verify deletion
Start-Sleep -Seconds 600
az group show --name aks-event-rg 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "✓ All resources cleaned up successfully" -ForegroundColor Green
}
```

---

## Summary

### 🎯 Key Takeaways

| Metric | Value |
|--------|-------|
| **3-Day Event Cost** | $146 - $280 |
| **Recommended (Average)** | **$213** |
| **Hourly Rate** | $2 - $4/hour |
| **Monthly (if sustained)** | $1,457 - $2,798 |
| **Cost per Node (3-day)** | $16.76 |

### 💡 Cost Breakdown

| Component | % of Total |
|-----------|------------|
| Compute (VMs) | 75% |
| Monitoring | 8% |
| Control Plane | 6% |
| Storage | 5% |
| Networking + ACR | 6% |

### ✅ Optimizations Applied

- ✓ **Standard SSD** - 51% cheaper than Premium
- ✓ **Basic ACR** - 95% cheaper than Premium with geo-replication
- ✓ **Single Environment** - 50% infrastructure savings
- ✓ **Event-Based Deployment** - Only pay for 3 days, not full month
- ✓ **Terraform Automation** - Rapid deploy and destroy

### 📊 Recommended Configuration

For a typical 3-day event with standard traffic:
- **Nodes:** Start with 7, scale to 11 average, 15 peak
- **Budget:** $300 (includes 25% buffer)
- **Duration:** 72-76 hours (including setup/teardown)
- **Expected Cost:** $210-220

---

**Document Version:** 2.0 (Event-Optimized)  
**Last Updated:** March 17, 2026  
**Optimized For:** 3-day event workloads  
**Cost Focus:** 3-day and monthly projections only
