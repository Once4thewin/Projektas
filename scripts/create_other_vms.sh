#!/bin/bash
set -e

source "$ROOT_DIR/.vm_info"

echo "Creating remaining VMs across team members..."
echo ""

# Read remaining team members (skip first line - ansible VM)
tail -n +2 "$CONFIG_FILE" | while IFS=':' read -r username password_b64 vmtype; do
    # Remove single quotes and whitespace from password
    username=$(echo "$username" | xargs)
    password_b64=$(echo "$password_b64" | tr -d "'" | xargs)
    vmtype=$(echo "$vmtype" | xargs)
    
    # Decode base64 password
    password=$(echo "$password_b64" | base64 -d)
    
    echo "=========================================="
    echo "Creating $vmtype-vm for user: $username"
    echo "=========================================="
    
    # Create VM
    VMREZ=$(onetemplate instantiate "$TEMPLATE" --name "$vmtype-vm" \
      --user "$username" --password "$password" --endpoint "$ENDPOINT" 2>&1)
    
    VMID=$(echo "$VMREZ" | grep -oP 'ID: \K\d+')
    
    if [ -z "$VMID" ]; then
        echo "ERROR: Failed to create $vmtype-vm"
        echo "Response: $VMREZ"
        echo "Continuing with next VM..."
        echo ""
        continue
    fi
    
    echo "$vmtype-vm created with ID: $VMID"
    
    # Wait for VM to be running
    echo "Waiting for $vmtype-vm to start..."
    VM_READY=false
    for i in {1..60}; do
        VM_STATE=$(onevm show "$VMID" --user "$username" --password "$password" \
          --endpoint "$ENDPOINT" --json 2>/dev/null | \
          jq -r '.VM.STATE // empty')
        
        if [ "$VM_STATE" == "3" ]; then
            echo "$vmtype-vm is running!"
            VM_READY=true
            break
        fi
        
        echo "Attempt $i/60: State=$VM_STATE"
        sleep 10
    done
    
    if [ "$VM_READY" = false ]; then
        echo "ERROR: $vmtype-vm did not start in time"
        echo "Continuing with next VM..."
        echo ""
        continue
    fi
    
    # Get VM IP
    VM_IP=$(onevm show "$VMID" --user "$username" --password "$password" \
      --endpoint "$ENDPOINT" --json 2>/dev/null | \
      jq -r '.VM.TEMPLATE.NIC[0].IP // empty')
    
    if [ -z "$VM_IP" ] || [ "$VM_IP" == "null" ]; then
        echo "ERROR: Could not get IP for $vmtype-vm"
        echo "Continuing with next VM..."
        echo ""
        continue
    fi
    
    echo "$vmtype-vm IP: $VM_IP"
    
    # Save VM info
    echo "${vmtype}_VM_IP=$VM_IP" >> "$ROOT_DIR/.vm_info"
    echo "${vmtype}_VM_ID=$VMID" >> "$ROOT_DIR/.vm_info"
    
    # Wait for SSH
    echo "Waiting for SSH on $vmtype-vm..."
    SSH_READY=false
    for i in {1..30}; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
           "root@$VM_IP" "echo 'SSH ready'" 2>/dev/null; then
            echo "SSH is ready on $vmtype-vm!"
            SSH_READY=true
            break
        fi
        echo "Waiting for SSH... ($i/30)"
        sleep 10
    done
    
    if [ "$SSH_READY" = false ]; then
        echo "WARNING: SSH not ready on $vmtype-vm"
    fi
    
    # Add to ansible-vm known_hosts
    echo "Adding $vmtype-vm to ansible-vm known_hosts..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR "root@$ANSIBLE_VM_IP" \
      "ssh-keyscan -H $VM_IP >> ~/.ssh/known_hosts 2>/dev/null" || true
    
    echo "$vmtype-vm setup complete!"
    echo ""
done

# Reload .vm_info to get all IPs
source "$ROOT_DIR/.vm_info"

# Generate Ansible inventory
echo "Generating Ansible inventory..."
cat > "$ANSIBLE_DIR/inventory.ini" << EOF
[database]
db-vm ansible_host=${db_VM_IP} ansible_user=root

[webserver]
webserver-vm ansible_host=${webserver_VM_IP} ansible_user=root

[client]
client-vm ansible_host=${client_VM_IP} ansible_user=root

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Ansible inventory created!"
echo ""
echo "=========================================="
echo "All VMs created successfully!"
echo "=========================================="
echo "VM Information:"
cat "$ROOT_DIR/.vm_info"