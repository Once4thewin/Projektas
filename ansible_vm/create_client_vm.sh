#!/bin/bash
set -e

# Script to create client-vm in team member 4's OpenNebula account

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$ROOT_DIR/../config/team_members.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    IFS=':' read -r USERNAME ENDPOINT TEMPLATE <<< "$TEAM_MEMBER_4"
else
    echo "Error: team_members.conf not found"
    exit 1
fi

echo "Creating client-vm in $USERNAME's OpenNebula account..."

VM_TEMPLATE=$(cat <<EOF
NAME = "client-vm"
CPU = 2
MEMORY = 4096
DISK = [ IMAGE_ID = "0" ]
NIC = [ NETWORK_ID = "0" ]
GRAPHICS = [ TYPE = "VNC", LISTEN = "0.0.0.0" ]
OS = [ ARCH = "x86_64", BOOT = "hd" ]
CONTEXT = [ NETWORK = "YES", SSH_PUBLIC_KEY = "\$USER[SSH_PUBLIC_KEY]" ]
EOF
)

echo "$VM_TEMPLATE" | onevm create -u "$USERNAME" - || {
    echo "Error: Failed to create client-vm"
    exit 1
}

sleep 30
VM_ID=$(onevm list -u "$USERNAME" | grep client-vm | awk '{print $1}')
VM_IP=$(onevm show "$VM_ID" -u "$USERNAME" | grep IP | head -1 | awk '{print $2}')

echo "client-vm IP: $VM_IP"
echo "client_VM_IP=$VM_IP" >> "$ROOT_DIR/../.vm_info"

