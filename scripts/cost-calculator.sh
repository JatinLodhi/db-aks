#!/bin/bash

# AKS Cost Estimation and Capacity Planning Script
# Helps estimate costs and capacity for different configurations

echo "=========================================="
echo "AKS Cost & Capacity Calculator"
echo "=========================================="
echo ""

# VM SKU pricing (East US region - approximate monthly costs)
# Source: Azure Pricing Calculator as of March 2024
declare -A VM_COSTS
VM_COSTS["Standard_D2s_v5"]=69    # 2 vCPU, 8GB
VM_COSTS["Standard_D4s_v5"]=138   # 4 vCPU, 16GB
VM_COSTS["Standard_D8s_v5"]=276   # 8 vCPU, 32GB
VM_COSTS["Standard_D16s_v5"]=552  # 16 vCPU, 64GB
VM_COSTS["Standard_D32s_v5"]=1104 # 32 vCPU, 128GB

# Estimated concurrent users per VM SKU (conservative estimates)
# Assumes typical web application (stateless, moderate compute)
declare -A USERS_PER_NODE
USERS_PER_NODE["Standard_D2s_v5"]=150
USERS_PER_NODE["Standard_D4s_v5"]=350
USERS_PER_NODE["Standard_D8s_v5"]=700
USERS_PER_NODE["Standard_D16s_v5"]=1400
USERS_PER_NODE["Standard_D32s_v5"]=2800

# Function to calculate costs and capacity
calculate_scenario() {
    local vm_size=$1
    local min_nodes=$2
    local max_nodes=$3
    local num_pools=$4
    
    local vm_cost=${VM_COSTS[$vm_size]}
    local users_per_node=${USERS_PER_NODE[$vm_size]}
    
    local min_total_nodes=$((min_nodes * num_pools))
    local max_total_nodes=$((max_nodes * num_pools))
    
    local min_monthly_cost=$((vm_cost * min_total_nodes))
    local max_monthly_cost=$((vm_cost * max_total_nodes))
    
    local min_capacity=$((users_per_node * min_total_nodes))
    local max_capacity=$((users_per_node * max_total_nodes))
    
    echo "Configuration: $vm_size × $num_pools pools"
    echo "  Nodes: $min_total_nodes (min) to $max_total_nodes (max)"
    echo "  Cost: \$$min_monthly_cost/mo (min) to \$$max_monthly_cost/mo (max)"
    echo "  Capacity: ${min_capacity} users (min) to ${max_capacity} users (max)"
    echo ""
}

echo "Target: 100,000 concurrent users"
echo ""

echo "=========================================="
echo "Recommended Configurations"
echo "=========================================="
echo ""

echo "Option 1: Balanced (RECOMMENDED)"
calculate_scenario "Standard_D8s_v5" 20 150 2
echo "  ✓ Good balance of cost and capacity"
echo "  ✓ 150k-210k max capacity (50%+ overhead)"
echo "  ✓ Efficient resource utilization"
echo ""

echo "Option 2: Cost-Optimized"
calculate_scenario "Standard_D16s_v5" 15 75 2
echo "  ✓ Fewer nodes, lower baseline cost"
echo "  ✓ 210k max capacity"
echo "  ✓ Higher utilization per node"
echo ""

echo "Option 3: High Resilience"
calculate_scenario "Standard_D8s_v5" 30 200 2
echo "  ✓ Higher baseline capacity (42k users)"
echo "  ✓ 280k max capacity (180%+ overhead)"
echo "  ✓ More headroom for traffic spikes"
echo ""

echo "Option 4: Budget-Conscious"
calculate_scenario "Standard_D4s_v5" 30 200 2
echo "  ✓ Lowest per-node cost"
echo "  ✓ 140k max capacity"
echo "  ✗ Less headroom, may struggle with spikes"
echo ""

echo "=========================================="
echo "Additional Cost Components"
echo "=========================================="
echo ""

echo "System Node Pool: 3-6 × Standard_D4s_v5"
echo "  Cost: \$414-828/mo"
echo ""

echo "Azure Container Registry (Premium):"
echo "  Base: \$220/mo"
echo "  Geo-replication: \$30/mo"
echo "  Total: ~\$250/mo"
echo ""

echo "Azure Monitor & Log Analytics:"
echo "  Estimated: \$200-500/mo (depends on log volume)"
echo ""

echo "Load Balancer & Public IPs:"
echo "  Standard LB: \$25/mo"
echo "  4 Public IPs: \$16/mo"
echo "  Total: ~\$41/mo"
echo ""

echo "Storage (for persistent volumes, if used):"
echo "  Premium SSD: \$0.13/GB-month"
echo "  Example: 1TB = \$130/mo"
echo ""

echo "=========================================="
echo "Cost Optimization Strategies"
echo "=========================================="
echo ""

echo "1. Reserved Instances (1-year or 3-year)"
echo "   Savings: 40-60% on compute costs"
echo "   Example: D8s_v5 reserved = \$110-165/mo instead of \$276/mo"
echo ""

echo "2. Spot VMs for non-critical workloads"
echo "   Savings: 60-80% on compute costs"
echo "   Risk: Can be evicted with 30-second notice"
echo ""

echo "3. Aggressive autoscaling"
echo "   Set lower min_count during off-peak hours"
echo "   Example: Scale to 30 nodes at night, 100+ during day"
echo ""

echo "4. Right-sizing applications"
echo "   Optimize resource requests/limits"
echo "   Reduce over-provisioning"
echo ""

echo "=========================================="
echo "Capacity Planning Factors"
echo "=========================================="
echo ""

echo "Users per node estimate depends on:"
echo "  • Application CPU/memory footprint"
echo "  • Request rate per user (req/sec)"
echo "  • Session duration"
echo "  • Background jobs/cron tasks"
echo "  • Database query complexity"
echo ""

echo "For MORE users per node:"
echo "  ✓ Implement aggressive caching (Redis)"
echo "  ✓ Use CDN for static assets"
echo "  ✓ Optimize database queries"
echo "  ✓ Implement connection pooling"
echo "  ✓ Use async processing for heavy tasks"
echo ""

echo "For FEWER users per node (more resilience):"
echo "  ✓ Complex real-time features (WebSockets)"
echo "  ✓ Heavy computation per request"
echo "  ✓ High memory usage per session"
echo "  ✓ Need for burst capacity"
echo ""

echo "=========================================="
echo "Load Testing Recommendations"
echo "=========================================="
echo ""

echo "Before production deployment:"
echo "  1. Run load tests with realistic scenarios"
echo "  2. Measure actual users per node"
echo "  3. Test autoscaling behavior"
echo "  4. Verify pod startup time"
echo "  5. Test failure scenarios (node failure, pod crashes)"
echo ""

echo "Recommended tools:"
echo "  • k6 (Grafana Labs)"
echo "  • Apache JMeter"
echo "  • Locust"
echo "  • Azure Load Testing"
echo ""

echo "=========================================="
echo "Custom Calculation"
echo "=========================================="
echo ""

read -p "Calculate for custom configuration? (yes/no): " CUSTOM
if [ "$CUSTOM" == "yes" ]; then
    echo ""
    echo "Available VM sizes:"
    echo "  1. Standard_D4s_v5 (4 vCPU, 16GB) - \$138/mo"
    echo "  2. Standard_D8s_v5 (8 vCPU, 32GB) - \$276/mo"
    echo "  3. Standard_D16s_v5 (16 vCPU, 64GB) - \$552/mo"
    echo "  4. Standard_D32s_v5 (32 vCPU, 128GB) - \$1104/mo"
    
    read -p "Select VM size (1-4): " VM_CHOICE
    
    case $VM_CHOICE in
        1) VM_SIZE="Standard_D4s_v5" ;;
        2) VM_SIZE="Standard_D8s_v5" ;;
        3) VM_SIZE="Standard_D16s_v5" ;;
        4) VM_SIZE="Standard_D32s_v5" ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
    
    read -p "Minimum nodes per pool: " MIN_NODES
    read -p "Maximum nodes per pool: " MAX_NODES
    read -p "Number of user node pools: " NUM_POOLS
    
    echo ""
    echo "=========================================="
    calculate_scenario "$VM_SIZE" "$MIN_NODES" "$MAX_NODES" "$NUM_POOLS"
    echo "=========================================="
fi

echo ""
echo "Note: Prices are approximate for East US region."
echo "Check Azure Pricing Calculator for exact pricing in your region."
echo ""
