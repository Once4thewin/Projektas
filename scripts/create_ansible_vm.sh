#!/bin/bash
set -e

# Read first team member (ansible VM owner)
MEMBER_LINE=$(head -n 1 "$CONFIG_FILE")

# Extract fields - handle single quotes around base64 password
CUSER=$(echo "$MEMBER_LINE" | cut -d':' -f1)
CPASS_B64=$(echo "$MEMBER_LINE" | cut -d':' -f2 | tr -d "'")
CPASS=$(echo "$CPASS_B64" | base64 -d)

echo "Creating ansible-vm for user: $CUSER"

# Install OpenNebula tools locally if not present
if ! command -v onevm &> /dev/null; then
    echo "Installing OpenNebula tools..."
    wget -q -O- https://downloads.opennebula.org/repo/repo.key | \
      sudo apt-key add -
    echo "deb https://downloads.opennebula.org/repo/5.6/Ubuntu/18.04 stable opennebula" | \
      sudo tee /etc/apt/sources.list.d/opennebula.list
    sudo apt update -y
    sudo apt install -y opennebula-tools jq
fi

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

# Create VM
echo "Instantiating ansible-vm template..."
VMREZ=$(onetemplate instantiate "$TEMPLATE" --name "ansible-vm" \
  --user "$CUSER" --password "$CPASS" --endpoint "$ENDPOINT" 2>&1)

VMID=$(echo "$VMREZ" | grep -oP 'ID: \K\d+')

if [ -z "$VMID" ]; then
    echo "ERROR: Failed to create ansible-vm"
    echo "Response: $VMREZ"
    exit 1
fi

echo "Ansible VM created with ID: $VMID"

# Wait for VM to reach running state
echo "Waiting for ansible-vm to start..."
for i in {1..60}; do
    VM_STATE=$(onevm show "$VMID" --user "$CUSER" --password "$CPASS" \
      --endpoint "$ENDPOINT" --json 2>/dev/null | \
      jq -r '.VM.STATE // empty')
    
    if [ "$VM_STATE" == "3" ]; then
        echo "Ansible VM is running!"
        break
    fi
    
    if [ $i -eq 60 ]; then
        echo "ERROR: VM did not reach running state in time"
        exit 1
    fi
    
    echo "Attempt $i/60: State=$VM_STATE"
    sleep 10
done

# Get VM IP address
echo "Getting VM IP address..."
ANSIBLE_VM_IP=$(onevm show "$VMID" --user "$CUSER" --password "$CPASS" \
  --endpoint "$ENDPOINT" --json 2>/dev/null | \
  jq -r '.VM.TEMPLATE.NIC[0].IP // empty')

if [ -z "$ANSIBLE_VM_IP" ] || [ "$ANSIBLE_VM_IP" == "null" ]; then
    echo "ERROR: Could not get VM IP address"
    exit 1
fi

echo "Ansible VM IP: $ANSIBLE_VM_IP"

# Wait for SSH to be available
echo "Waiting for SSH service..."
for i in {1..30}; do
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
       -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
       "root@$ANSIBLE_VM_IP" "echo 'SSH ready'" 2>/dev/null; then
        echo "SSH is ready!"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "WARNING: SSH did not become ready, but continuing..."
        break
    fi
    
    echo "Waiting for SSH... ($i/30)"
    sleep 10
done

# Export variables for use in other scripts
export ANSIBLE_VM_ID="$VMID"
export ANSIBLE_VM_IP="$ANSIBLE_VM_IP"
export ANSIBLE_USER="$CUSER"
export ANSIBLE_PASS="$CPASS"

# Save to file
cat > "$ROOT_DIR/.vm_info" << EOF
ANSIBLE_VM_ID=$VMID
ANSIBLE_VM_IP=$ANSIBLE_VM_IP
ANSIBLE_USER=$CUSER
ANSIBLE_PASS=$CPASS
EOF

echo "Ansible VM created successfully!"
echo "  User: $CUSER"
echo "  IP: $ANSIBLE_VM_IP"
echo "  ID: $VMID"