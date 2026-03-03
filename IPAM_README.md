# Automated IPAM System

## Overview

This directory contains an automated IP Address Management (IPAM) system that:
- Tracks IP allocations in `ipam.csv`
- Automatically calculates IP ranges using the `modules/ipam` Terraform module
- Prevents conflicts and overlaps
- Provides easy tracking and management

## Files

- **`ipam.csv`** - CSV tracker with all IP allocations (human-readable, Excel-compatible)
- **`ipam_updater.py`** - Python script to manage CSV updates
- **`modules/ipam/`** - Terraform module for automatic IP calculation

## IP Allocation Strategy

**Master Range**: `10.1.0.0/16` (65,536 IPs)

### Environment Blocks (Realms)

| Realm | CIDR | Available `/22` Blocks | Region Capacity | IPs per Env |
|:---|:---|:---|:---|:---|
| Common | `10.1.0.0/18` | 16 | 4 (max 4 regions) | 16,384 |
| Prod | `10.1.64.0/18` | 16 | 4 (max 4 regions) | 16,384 |
| PreProd | `10.1.128.0/18` | 16 | 4 (max 4 regions) | 16,384 |
| NonProd | `10.1.192.0/18` | 16 | N/A | 16,384 |

*Note: For each Realm, we can split into 2 main regions (one primary region and one secondary region).*

#### Common Realm Architecture (`10.1.0.0/18`)

| Purpose | CIDR | Why |
|:---|:---|:---|
| Transit routing core | `10.1.0.0/22` | Hub routing |
| Palo Alto HA | `10.1.4.0/26` | HA pair |
| ILB VIP pool | `10.1.4.64/26` | VIP pool |
| NAT | `10.1.4.128/26` | Egress |
| Shared services | `10.1.8.0/22` | DNS, logging |
| Reserved | remainder | Growth |

#### App Environments (Prod, PreProd, NonProd) Architecture

For the application environments, subnet allocation follows variable sizing based on the resource type rather than a single fixed size:

| Purpose | CIDR Size |
|:---|:---|
| GKE Nodes (Primary) | `/24` per nodepool |
| GKE Pods (Secondary) | `/21` per cluster |
| GKE Services (Secondary) | `/25` per cluster |
| VM workloads | `/22` |
| DB subnet | `/24` |
| ILB | `/26` |
| Reserved | remainder | Growth |

### Allocation Pattern

**Primary Subnets (Dynamically Assigned):**
The IPAM script automatically reserves a dedicated block of 4 `/22` subnets (a `/20` equivalent) for every **newly discovered region** in an environment.
- When you allocate the *first* subnet in a new region, it is assigned the next available 4-block chunk in the environment.
- Subsequent subnets in the *same* region will use the next free `/22` inside that region's dedicated 4-block chunk.

**Secondary Ranges (GKE - Dynamically Assigned):**
GKE Pod and Service ranges use RFC1918 ranges from the subnet ranges only. They are allocated out of the primary environment blocks rather than detached 100.64/172.16 blocks to unify routing.
- **GKE Pods:** Allocated dynamically from the available RFC1918 environment subnet space (e.g., dynamically registered in CSV).
- **GKE Services:** Allocated dynamically from the available RFC1918 environment subnet space (e.g., dynamically registered in CSV).

### Expected Manual Updates for New Subnets (Decoupled Architecture)

**IMPORTANT:** Terraform and the IPAM Tracker (`ipam.csv`) are completely decoupled. The automated Terraform logic calculates variables based entirely on the state stored securely as text inside `ipam.csv`.

When allocating **any new subnet** (Primary Nodes, Secondary Pods, or Services), you are expected to follow these manual steps to ensure accuracy across Dynamic Python logic and network configurations:

1. **Check Availability & IP Sizing**: Ensure you have chosen sizes consistent with GCP bounds (e.g., Nodes: `/24`, Pods: `/21`, Services: `/25`).
2. **Allocate & Commit to CSV Tracker**: You MUST run `python ipam_updater.py allocate ...` to register the new Subnets, Pods, and Service IPs inside `ipam.csv`. (Do this immediately to prevent conflicting claims).
3. **Hardcode in YAML Configuration**: Once your IPs are allocated and safely listed in `ipam.csv`, you must manually edit `foundation/config.yaml` (or respective config files) and assign those respective blocks precisely under the environment's `subnets` array. 
4. **Push/Run Terraform**: Because the configuration is now safely registered in `ipam.csv` and assigned into `config.yaml`, triggering `terraform apply` will calculate, construct and output resources properly.

## Using the IPAM System

### 1. View Current Allocations

```bash
# View all allocations
python ipam_updater.py list

# View specific environment
python ipam_updater.py list Prod
```

### 2. Get Next Available Range

```bash
python ipam_updater.py next Prod asia-south1
# Output: ✅ Next available: 10.1.68.0/22
```

### 3. Allocate a New Subnet

```bash
python ipam_updater.py allocate Prod Subnet prod-subnet-us-central1 10.1.80.0/22 us-central1 "Primary subnet for US region"
```

### 4. Use in Terraform

The IPAM module automatically calculates ranges:

```hcl
module "ipam" {
  source = "./modules/ipam"
}

# Reference calculated ranges
subnets = [
  {
    name   = "prod-subnet-asia-south1"
    cidr   = module.ipam.ipam_primary_subnets.prod["asia-south1"]
    region = "asia-south1"
  }
]
```

## Workflow for Adding New Subnets

1. **Check availability**: `python ipam_updater.py next <env> <region>`
2. **Update config.yaml**: Add subnet configuration
3. **Update CSV**: `python ipam_updater.py allocate ...`
4. **Apply Terraform**: `terraform apply`

## CSV Format

The `ipam.csv` file can be opened in Excel or any spreadsheet tool for easy tracking:

| Column | Description |
|:---|:---|
| Environment | Common, Prod, PreProd, NonProd |
| Resource_Type | VPC, Subnet, Secondary, Reserved |
| Resource_Name | Unique identifier |
| CIDR | IP range in CIDR notation |
| IP_Count | Number of available IPs |
| Region | GCP region or "global" |
| Status | Allocated, Reserved |
| Allocated_Date | Date of allocation |
| Notes | Additional information |

## Conflict Prevention

✅ **Automatic Validation**: Script checks for conflicts before allocation  
✅ **Clear Boundaries**: Each environment has dedicated `/18` block  
✅ **Tracking**: CSV shows all allocations with status  
✅ **Future-Proof**: 75% reserved for growth
