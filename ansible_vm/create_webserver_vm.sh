#!/bin/bash
set -e

# Script to create webserver-vm in team member 3's OpenNebula account

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$ROOT_DIR/../config/team_members.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    IFS=':' read -r USERNAME PASSWORD ENDPOINT TEMPLATE <<< "$TEAM_MEMBER_3"
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

echo "Creating webserver-vm in $USERNAME's OpenNebula account..."

VM_TEMPLATE=$(cat <<EOF
NAME = "webserver-vm"
CPU = 2
MEMORY = 4096
DISK = [ IMAGE_ID = "0" ]
NIC = [ NETWORK_ID = "0" ]
OS = [ ARCH = "x86_64", BOOT = "hd" ]
CONTEXT = [ NETWORK = "YES", SSH_PUBLIC_KEY = "\$USER[SSH_PUBLIC_KEY]" ]
EOF
)

echo "$VM_TEMPLATE" | onevm create - || {
    echo "Error: Failed to create webserver-vm"
    rm -f "$ONE_AUTH"
    exit 1
}

sleep 30
VM_ID=$(onevm list | grep webserver-vm | awk '{print $1}')
VM_IP=$(onevm show "$VM_ID" | grep IP | head -1 | awk '{print $2}')

echo "webserver-vm IP: $VM_IP"
echo "webserver_VM_IP=$VM_IP" >> "$ROOT_DIR/../.vm_info"

# Clean up auth file
rm -f "$ONE_AUTH"

