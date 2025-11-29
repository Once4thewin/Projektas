#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_VM_DIR="$ROOT_DIR/ansible_vm"
ANSIBLE_CONFIG_DIR="$ROOT_DIR/ansible_config"
CONFIG_FILE="$ROOT_DIR/config/team_members.conf"

export ROOT_DIR
export ANSIBLE_VM_DIR
export ANSIBLE_CONFIG_DIR
export CONFIG_FILE

echo "=== Hospital Management System Deployment ==="
echo ""

# Step 1: Create VMs in OpenNebula (distributed across team members)
echo "Step 1: Creating virtual machines in OpenNebula..."
echo "This will create VMs across team members' accounts (one VM per member)"
bash "$ANSIBLE_VM_DIR/ansible_vm.sh"
bash "$ANSIBLE_VM_DIR/create_db_vm.sh"
bash "$ANSIBLE_VM_DIR/create_webserver_vm.sh"
bash "$ANSIBLE_VM_DIR/create_client_vm.sh"

# Wait for VMs to be ready
echo ""
echo "Waiting for VMs to be ready..."
sleep 60

# Step 2: Bootstrap Ansible on ansible-vm
echo ""
echo "Step 2: Bootstrapping Ansible on ansible-vm..."
source "$ROOT_DIR/.vm_info"
ssh -o StrictHostKeyChecking=no "root@$ANSIBLE_VM_IP" "bash -s" < "$ANSIBLE_VM_DIR/bootstrap_ansible.sh"

# Step 3: Copy Ansible configuration to ansible-vm
echo ""
echo "Step 3: Copying Ansible configuration to ansible-vm..."
scp -r "$ANSIBLE_CONFIG_DIR"/* "root@$ANSIBLE_VM_IP:/root/ansible_config/"
scp -r "$ROOT_DIR/docker" "root@$ANSIBLE_VM_IP:/root/"
scp -r "$ROOT_DIR/hospital_app" "root@$ANSIBLE_VM_IP:/root/"

# Step 4: Update inventory with actual IPs
echo ""
echo "Step 4: Updating Ansible inventory with VM IPs..."
ssh "root@$ANSIBLE_VM_IP" << ENDSSH
cat > /root/ansible_config/inventory.yml << EOF
---
all:
  children:
    database:
      hosts:
        db-vm:
          ansible_host: ${db_VM_IP}
          ansible_user: root
    webserver:
      hosts:
        webserver-vm:
          ansible_host: ${webserver_VM_IP}
          ansible_user: root
    client:
      hosts:
        client-vm:
          ansible_host: ${client_VM_IP}
          ansible_user: root
EOF
ENDSSH

# Step 5: Run Ansible playbooks
echo ""
echo "Step 5: Running Ansible playbooks to configure all VMs..."
ssh "root@$ANSIBLE_VM_IP" << 'ENDSSH'
cd /root/ansible_config
ansible-playbook -i inventory.yml db_setup.yml
ansible-playbook -i inventory.yml webserver_setup.yml
ansible-playbook -i inventory.yml client_setup.yml
ENDSSH

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "VM Information:"
echo "  Ansible VM: $ANSIBLE_VM_IP"
echo "  Database VM: ${db_VM_IP}"
echo "  Webserver VM: ${webserver_VM_IP}"
echo "  Client VM: ${client_VM_IP}"
echo ""
echo "Access your hospital system at: http://${webserver_VM_IP}"
echo ""

