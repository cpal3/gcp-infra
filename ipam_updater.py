#!/usr/bin/env python3
"""
IPAM CSV Updater
Automatically updates ipam.csv when new resources are allocated
"""

import csv
import sys
import ipaddress
from datetime import datetime
from pathlib import Path

IPAM_CSV = Path(__file__).parent / "ipam.csv"

def read_ipam():
    """Read current IPAM allocations"""
    allocations = []
    with open(IPAM_CSV, 'r') as f:
        reader = csv.DictReader(f)
        allocations = list(reader)
    return allocations

def write_ipam(allocations):
    """Write updated IPAM allocations"""
    fieldnames = ['Environment', 'Resource_Type', 'Resource_Name', 'CIDR', 
                  'IP_Count', 'Region', 'Status', 'Allocated_Date', 'Notes']
    with open(IPAM_CSV, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(allocations)

def allocate_subnet(environment, resource_type, resource_name, cidr, region, notes=""):
    """Allocate a new subnet and update CSV"""
    allocations = read_ipam()
    
    # Check for conflicts
    for alloc in allocations:
        if alloc['CIDR'] == cidr and alloc['Status'] == 'Allocated':
            print(f"❌ ERROR: CIDR {cidr} already allocated to {alloc['Resource_Name']}")
            return False
    
    # Calculate usable IP count from CIDR (excluding network and broadcast addresses)
    prefix = int(cidr.split('/')[-1])
    ip_count = (2 ** (32 - prefix)) - 2
    
    # Add new allocation
    new_alloc = {
        'Environment': environment,
        'Resource_Type': resource_type,
        'Resource_Name': resource_name,
        'CIDR': cidr,
        'IP_Count': str(ip_count),
        'Region': region,
        'Status': 'Allocated',
        'Allocated_Date': datetime.now().strftime('%Y-%m-%d'),
        'Notes': notes
    }
    
    allocations.append(new_alloc)
    write_ipam(allocations)
    print(f"✅ Allocated {cidr} to {resource_name} in {environment}/{region}")
    return True

def list_available(environment=None):
    """List available IP ranges"""
    allocations = read_ipam()
    
    print("\n📊 IPAM Status Report\n" + "="*80)
    
    for alloc in allocations:
        if environment and alloc['Environment'] != environment:
            continue
        
        env_str = alloc.get('Environment', '') or ''
        type_str = alloc.get('Resource_Type', '') or ''
        cidr_str = alloc.get('CIDR', '') or ''
        status_str = alloc.get('Status', '') or ''
        name_str = alloc.get('Resource_Name', '') or ''
        
        status_icon = "✅" if status_str == "Allocated" else "🔲"
        print(f"{status_icon} {env_str:15} | {type_str:10} | "
              f"{cidr_str:20} | {status_str:10} | {name_str}")

def get_next_available(environment, region, target_prefix=22):
    """Get next available subnet for environment/region dynamically.
    
    Uses ipaddress module to scan the master environment block for the
    first available subnet of the requested size.
    """
    allocations = read_ipam()
    
    env_bases = {'Common': 0, 'Prod': 64, 'PreProd': 128, 'NonProd': 192}
    if environment not in env_bases:
        print(f"❌ Unknown environment: {environment}. Must be one of {list(env_bases.keys())}")
        return None
        
    env_base = env_bases[environment]
    master_env_net = ipaddress.IPv4Network(f"10.1.{env_base}.0/18")
    
    # Gather all allocated subnets
    allocated_nets = []
    for a in allocations:
        if a.get('Status') == 'Allocated' and '10.1.' in a.get('CIDR', ''):
            try:
                allocated_nets.append(ipaddress.IPv4Network(a['CIDR']))
            except ValueError:
                pass

    # Find the first available subnet of the requested size
    for candidate in master_env_net.subnets(new_prefix=target_prefix):
        conflict = False
        for alloc in allocated_nets:
            if candidate.overlaps(alloc):
                conflict = True
                break
        if not conflict:
            print(f"✅ Next available for {environment}/{region} (/{target_prefix}): {candidate}")
            return str(candidate)

    print(f"❌ No available /{target_prefix} blocks left in {environment}")
    return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python ipam_updater.py list [environment]")
        print("  python ipam_updater.py next <environment> <region> [--size <prefix>]")
        print("  python ipam_updater.py allocate <env> <type> <name> <cidr> <region> [notes]")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "list":
        env = sys.argv[2] if len(sys.argv) > 2 else None
        list_available(env)
    
    elif command == "next":
        if len(sys.argv) < 4:
            print("Usage: python ipam_updater.py next <environment> <region> [--size <prefix>]")
            sys.exit(1)
            
        target_prefix = 22
        if len(sys.argv) >= 6 and sys.argv[4] == "--size":
            target_prefix = int(sys.argv[5])
            
        get_next_available(sys.argv[2], sys.argv[3], target_prefix)
    
    elif command == "allocate":
        if len(sys.argv) < 7:
            print("Usage: python ipam_updater.py allocate <env> <type> <name> <cidr> <region> [notes]")
            sys.exit(1)
        notes = sys.argv[7] if len(sys.argv) > 7 else ""
        allocate_subnet(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6], notes)
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
