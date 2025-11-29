#!/bin/bash
set -e

# Script to create and configure the Ansible VM using OpenNebula
# This script creates the ansible-vm in the first team member's OpenNebula account

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$ROOT_DIR/../config/team_members.conf"

# Source team member configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    # Parse TEAM_MEMBER_1 for ansible-vm (format: username:password:endpoint:template)
    IFS=':' read -r USERNAME PASSWORD ENDPOINT TEMPLATE <<< "$TEAM_MEMBER_1"
else
    echo "Error: team_members.conf not found"
    exit 1
fi

# Set OpenNebula authentication
export ONE_XMLRPC="$ENDPOINT"
export ONE_AUTH="$ROOT_DIR/../.one_auth_${USERNAME}"

# Create ONE_AUTH file with username:password
echo "${USERNAME}:${PASSWORD}" > "$ONE_AUTH"
chmod 600 "$ONE_AUTH"

echo "Creating Ansible VM in $USERNAME's OpenNebula account..."

# OpenNebula VM creation template
VM_TEMPLATE=$(cat <<EOF
NAME = "ansible-vm"
CPU = 1
MEMORY = 2048
DISK = [
  IMAGE_ID = "0"
]
NIC = [
  NETWORK_ID = "0"
]
GRAPHICS = [
  TYPE = "VNC",
  LISTEN = "0.0.0.0"
]
OS = [
  ARCH = "x86_64",
  BOOT = "hd"
]
CONTEXT = [
  NETWORK = "YES",
  SSH_PUBLIC_KEY = "\$USER[SSH_PUBLIC_KEY]"
]
EOF
)

# Create VM using onevm create command
# Use ONE_AUTH for non-interactive authentication
echo "$VM_TEMPLATE" | onevm create - || {
    echo "Error: Failed to create VM. Check OpenNebula credentials and endpoint."
    rm -f "$ONE_AUTH"
    exit 1
}

echo "Ansible VM created successfully."
echo "Waiting for VM to be ready..."
sleep 30

# Get VM IP address
VM_ID=$(onevm list | grep ansible-vm | awk '{print $1}')
VM_IP=$(onevm show "$VM_ID" | grep IP | head -1 | awk '{print $2}')

echo "Ansible VM IP: $VM_IP"
echo "ANSIBLE_VM_IP=$VM_IP" > "$ROOT_DIR/../.vm_info"

# Clean up auth file
rm -f "$ONE_AUTH"

