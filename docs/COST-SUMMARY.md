# Azure AKS Infrastructure - Cost Summary

**Generated:** March 17, 2026  
**Region:** East US  
**Instance Type:** Standard_D4s_v5 (4 vCPU, 16GB RAM)  
**Currency:** USD

---

## Cost Overview

### Total Cost Estimates

| Configuration | **3-Day Cost** | **Monthly Cost** | **Cost per Hour** |
|---------------|----------------|------------------|-------------------|
| **Base (7 nodes)** | **$145.73** | **$1,457.20** | **$2.02/hr** |
| **Average (11 nodes)** | **$212.77** | **$2,127.60** | **$2.95/hr** |
| **Peak (15 nodes)** | **$279.81** | **$2,798.00** | **$3.88/hr** |

> **Recommended Budget for 3-Day Event:** $300 (covers peak with buffer)

---

## Detailed Service Breakdown

### 1. Compute Resources (AKS Nodes)

**VM Type:** Standard_D4s_v5 (4 vCPU, 16GB RAM)  
**Cost per VM:** $0.219/hour | $158.00/month | $15.77/3-days

| Node Pool | Node Count | 3-Day Cost | Monthly Cost | Notes |
|-----------|------------|------------|--------------|-------|
| System Pool | 3 nodes | $47.40 | $474.00 | Core services |
| Frontend Pool | 2-8 nodes | $31.60-$126.40 | $316.00-$1,264.00 | User-facing apps |
| Backend Pool | 2-7 nodes | $31.60-$110.60 | $316.00-$1,106.00 | APIs/services |

**Scaling Configuration:**
- **Base Configuration:** 7 nodes total = $110.60 (3-day) / $1,106.00 (monthly)
- **Average Configuration:** 11 nodes total = $173.80 (3-day) / $1,738.00 (monthly)
- **Peak Configuration:** 15 nodes total = $237.00 (3-day) / $2,370.00 (monthly)

### 2. AKS Control Plane

| Tier | 3-Day Cost | Monthly Cost | SLA | Notes |
|------|------------|--------------|-----|-------|
| **Standard** | **$7.30** | **$73.00** | **99.5%** | **Recommended** |

### 3. Storage Costs

**OS Disks - Standard SSD (E10, 128 GB per node)**

| Configuration | Nodes | 3-Day Cost | Monthly Cost | Notes |
|---------------|-------|------------|--------------|-------|
| Base | 7 | $6.72 | $67.20 | $9.60/disk/month |
| Average | 11 | $10.56 | $105.60 | 51% cheaper than Premium SSD |
| Peak | 15 | $14.40 | $144.00 | 500 IOPS per disk |

**Additional Storage:**
- Persistent Volume Claims: $0.96/100GB (3-day) | $9.60/100GB (monthly)
- Container Image Storage: Included in ACR (up to 10 GB)

### 4. Networking

| Component | 3-Day Cost | Monthly Cost | Notes |
|-----------|------------|--------------|-------|
| Load Balancer (Standard) | $1.88 | $18.75 | Required for AKS |
| Load Balancer Rules | $0.80 | $8.00 | 10 rules |
| Public IP Address | $0.37 | $3.65 | 1 static IP |
| Data Transfer (outbound) | $0.00 | $0.00 | First 5 GB free |
| **Total Networking** | **$3.05** | **$30.40** | |

### 5. Container Registry (ACR)

| Tier | 3-Day Cost | Monthly Cost | Storage | Features |
|------|------------|--------------|---------|----------|
| **Basic** | **$1.50** | **$15.00** | **10 GB** | Unlimited pulls, Webhooks |

**Benefits:** 95% cost savings vs Premium tier, sufficient for event workloads

### 6. Monitoring & Logging

| Component | 3-Day Cost | Monthly Cost | Data Volume | Notes |
|-----------|------------|--------------|-------------|-------|
| Log Analytics Workspace | $16.56 | $165.60 | 2 GB/day | $2.76/GB |
| Container Insights | Included | Included | - | Built-in metrics |
| Data Retention | $0.00 | $0.00 | 31 days | Free included |
| **Total Monitoring** | **$16.56** | **$165.60** | **~6 GB (3-day)** | |

### 7. Additional Resources (No Cost)

| Component | 3-Day Cost | Monthly Cost | Notes |
|-----------|------------|--------------|-------|
| Virtual Network | $0.00 | $0.00 | No charge |
| Subnets | $0.00 | $0.00 | No charge |
| Managed Identity | $0.00 | $0.00 | No charge |
| Network Security Groups | $0.00 | $0.00 | No charge |

---

## Complete Cost Summary by Service

### 3-Day Event Costs

| Service | Base (7 nodes) | Average (11 nodes) | Peak (15 nodes) |
|---------|----------------|--------------------|-----------------|
| **AKS Control Plane** | $7.30 | $7.30 | $7.30 |
| **Compute (VMs)** | $110.60 | $173.80 | $237.00 |
| **Storage (Standard SSD)** | $6.72 | $10.56 | $14.40 |
| **Networking** | $3.05 | $3.05 | $3.05 |
| **Container Registry** | $1.50 | $1.50 | $1.50 |
| **Monitoring & Logs** | $16.56 | $16.56 | $16.56 |
| **Additional Resources** | $0.00 | $0.00 | $0.00 |
| **TOTAL (3-Day)** | **$145.73** | **$212.77** | **$279.81** |

### Monthly Cost Projection

| Service | Base (7 nodes) | Average (11 nodes) | Peak (15 nodes) |
|---------|----------------|--------------------|-----------------|
| **AKS Control Plane** | $73.00 | $73.00 | $73.00 |
| **Compute (VMs)** | $1,106.00 | $1,738.00 | $2,370.00 |
| **Storage (Standard SSD)** | $67.20 | $105.60 | $144.00 |
| **Networking** | $30.40 | $30.40 | $30.40 |
| **Container Registry** | $15.00 | $15.00 | $15.00 |
| **Monitoring & Logs** | $165.60 | $165.60 | $165.60 |
| **Additional Resources** | $0.00 | $0.00 | $0.00 |
| **TOTAL (Monthly)** | **$1,457.20** | **$2,127.60** | **$2,798.00** |

---

## Cost Breakdown by Service (Percentage)

### 3-Day Event - Average Configuration ($212.77)

| Service | Cost | Percentage |
|---------|------|------------|
| Compute (VMs) | $173.80 | **81.7%** |
| Monitoring & Logs | $16.56 | 7.8% |
| Storage | $10.56 | 5.0% |
| AKS Control Plane | $7.30 | 3.4% |
| Networking | $3.05 | 1.4% |
| Container Registry | $1.50 | 0.7% |

### Monthly - Average Configuration ($2,127.60)

| Service | Cost | Percentage |
|---------|------|------------|
| Compute (VMs) | $1,738.00 | **81.7%** |
| Monitoring & Logs | $165.60 | 7.8% |
| Storage | $105.60 | 5.0% |
| AKS Control Plane | $73.00 | 3.4% |
| Networking | $30.40 | 1.4% |
| Container Registry | $15.00 | 0.7% |

> **Key Insight:** Compute resources account for ~82% of total costs. Optimize node count and sizing for maximum savings.

---

## Quick Reference

### Hourly Costs

| Configuration | Cost per Hour | Daily Cost (24hr) |
|---------------|---------------|-------------------|
| Base (7 nodes) | $2.02 | $48.58 |
| Average (11 nodes) | $2.95 | $70.92 |
| Peak (15 nodes) | $3.88 | $93.27 |

### Cost Optimization Applied

| Optimization | Savings | Impact |
|--------------|---------|---------|
| Standard SSD vs Premium SSD | 51% per disk | $7.07 (3-day) / $70.77 (monthly) |
| Basic ACR vs Premium | 95% | $32.10 (3-day) / $321.00 (monthly) |
| Single environment vs Dual | ~50% | ~$145 (3-day) / ~$1,450 (monthly) |
| Event-optimized scaling | Variable | Cost scales with actual usage |

### Budget Recommendations

| Duration | Recommended Budget | Configuration Covered |
|----------|-------------------|----------------------|
| **3-Day Event** | **$300** | Peak + 7% buffer |
| **1 Week** | **$550** | Average configuration |
| **1 Month** | **$2,300** | Average configuration |

---

**Note:** All costs are estimates based on East US region pricing as of March 2026. Actual costs may vary based on usage patterns, data transfer, and Azure pricing changes. Monitor costs using Azure Cost Management for accurate tracking.
