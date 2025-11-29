#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"
ANSIBLE_DIR="$ROOT_DIR/ansible"
CONFIG_FILE="$ROOT_DIR/config/team_members.conf"

ENDPOINT="https://grid5.mif.vu.lt/cloud3/RPC2"
TEMPLATE="ubuntu-24.04"

export ROOT_DIR
export SCRIPTS_DIR
export ANSIBLE_DIR
export CONFIG_FILE
export ENDPOINT
export TEMPLATE

echo "=== Hospital Management System Deployment ==="
echo "Step 1: Creating ansible-vm..."

# Create ansible VM (first team member)
source "$SCRIPTS_DIR/create_ansible_vm.sh"

echo ""
echo "Step 2: Setting up Ansible on ansible-vm..."
bash "$SCRIPTS_DIR/setup_ansible.sh"

echo ""
echo "Step 3: Creating other VMs across team members..."
bash "$SCRIPTS_DIR/create_other_vms.sh"

echo ""
echo "Step 4: Running Ansible playbooks..."
source "$ROOT_DIR/.vm_info"

# Copy ansible directory to ansible-vm
echo "Copying Ansible files to ansible-vm..."
scp -r "$ANSIBLE_DIR"/* "root@$ANSIBLE_VM_IP:/root/ansible/"

# Run playbooks from ansible-vm
echo "Executing Ansible playbooks..."
ssh "root@$ANSIBLE_VM_IP" << 'ENDSSH'
cd /root/ansible
ansible-playbook -i inventory.ini playbooks/db_setup.yml
ansible-playbook -i inventory.ini playbooks/webserver_setup.yml
ansible-playbook -i inventory.ini playbooks/client_setup.yml
ENDSSH

echo ""
echo "=== Deployment Complete ==="
echo "Ansible VM: $ANSIBLE_VM_IP"
echo "Database VM: ${db_VM_IP}"
echo "Webserver VM: ${webserver_VM_IP}"
echo "Client VM: ${client_VM_IP}"
echo ""
echo "Access your hospital system at: http://${webserver_VM_IP}"