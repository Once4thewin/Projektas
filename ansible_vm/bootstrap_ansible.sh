#!/bin/bash
set -e

# Script to bootstrap Ansible on the control node
# Installs Ansible and required dependencies

echo "Bootstrapping Ansible..."

# Update system
apt-get update

# Install Python and pip
apt-get install -y python3 python3-pip

# Install Ansible
pip3 install ansible

# Install additional Ansible collections if needed
ansible-galaxy collection install community.mysql
ansible-galaxy collection install community.docker

echo "Ansible bootstrap complete."

