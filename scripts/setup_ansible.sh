#!/bin/bash
set -e

source "$ROOT_DIR/.vm_info"

echo "Setting up Ansible on $ANSIBLE_VM_IP..."

# Install Ansible and dependencies on ansible-vm
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o LogLevel=ERROR "root@$ANSIBLE_VM_IP" << 'ENDSSH'

# Update system
echo "Updating system packages..."
apt update -y
apt install -y software-properties-common

# Install Ansible
echo "Installing Ansible..."
add-apt-repository -y ppa:ansible/ansible
apt update -y
apt install -y ansible python3-pip

# Install additional tools
echo "Installing additional tools..."
apt install -y git curl wget jq vim

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Verify installations
echo "Verifying installations..."
ansible --version
docker --version

# Create ansible directory
mkdir -p /root/ansible

echo "Ansible setup complete!"
ENDSSH

# Copy SSH key to ansible-vm
echo "Copying SSH keys to ansible-vm..."
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o LogLevel=ERROR ~/.ssh/id_rsa "root@$ANSIBLE_VM_IP:/root/.ssh/"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o LogLevel=ERROR ~/.ssh/id_rsa.pub "root@$ANSIBLE_VM_IP:/root/.ssh/"

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -o LogLevel=ERROR "root@$ANSIBLE_VM_IP" "chmod 600 /root/.ssh/id_rsa"

echo "Ansible setup completed successfully!"