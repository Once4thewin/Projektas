#!/bin/bash

# VM Manager Helper Script
# Provides functions to check VM status and extract information

ENDPOINT="https://grid5.mif.vu.lt/cloud3/RPC2"

# Function to get VM status
get_vm_status() {
    local vm_id=$1
    local username=$2
    local password=$3
    
    onevm show "$vm_id" --user "$username" --password "$password" \
      --endpoint "$ENDPOINT" --json 2>/dev/null | \
      jq -r '.VM.STATE_STR // "UNKNOWN"'
}

# Function to get VM IP
get_vm_ip() {
    local vm_id=$1
    local username=$2
    local password=$3
    
    onevm show "$vm_id" --user "$username" --password "$password" \
      --endpoint "$ENDPOINT" --json 2>/dev/null | \
      jq -r '.VM.TEMPLATE.NIC[0].IP // empty'
}

# Function to wait for VM to be running
wait_for_vm() {
    local vm_id=$1
    local username=$2
    local password=$3
    local max_attempts=${4:-60}
    
    echo "Waiting for VM $vm_id to be running..."
    for i in $(seq 1 $max_attempts); do
        STATUS=$(get_vm_status "$vm_id" "$username" "$password")
        IP=$(get_vm_ip "$vm_id" "$username" "$password")
        
        if [ "$STATUS" == "ACTIVE" ] && [ -n "$IP" ]; then
            echo "VM $vm_id is ACTIVE with IP: $IP"
            return 0
        fi
        
        echo "Attempt $i/$max_attempts: Status=$STATUS, IP=${IP:-none}"
        sleep 10
    done
    
    echo "ERROR: VM $vm_id did not become ready in time"
    return 1
}

# Export functions
export -f get_vm_status
export -f get_vm_ip
export -f wait_for_vm