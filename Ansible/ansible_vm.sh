#!/bin/bash

# Install OpenNebula tools
wget -q -O- https://downloads.opennebula.org/repo/repo.key | \
  sudo apt-key add -
echo "deb https://downloads.opennebula.org/repo/5.6/Ubuntu/18.04 stable opennebula" | \
  sudo tee /etc/apt/sources.list.d/opennebula.list

sudo apt update -y
sudo apt install -y opennebula-tools jq

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "ansible-vm-key"
fi

ssh-add ~/.ssh/id_rsa 2>/dev/null || true

# OpenNebula credentials
CUSER=pisa1147
CPASS=arnasvarnas12
CENDPOINT=https://grid5.mif.vu.lt/cloud3/RPC2
template="ubuntu-24.04"
VMname="ansible-vm"

# Create ansible VM
echo "Creating ansible-vm..."
CVMREZ=$(onetemplate instantiate $template --name $VMname \
  --user $CUSER --password $CPASS --endpoint $CENDPOINT)
CVMID=$(echo $CVMREZ | cut -d ' ' -f 3)
echo "Ansible VM ID: $CVMID"

# Wait for VM to be running
echo "Waiting for ansible-vm to start (this may take 1-2 minutes)..."
for i in {1..30}; do
    VM_STATE=$(onevm show $CVMID --user $CUSER --password $CPASS \
      --endpoint $CENDPOINT --json 2>/dev/null | \
      jq -r '.VM.STATE // empty')
    
    if [ "$VM_STATE" == "3" ]; then
        echo "Ansible VM is now running!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 10
done

# Get VM connection info
onevm show $CVMID --user $CUSER --password $CPASS \
  --endpoint $CENDPOINT > $CVMID.txt

CSSH_CON=$(cat $CVMID.txt | grep CONNECT_INFO1 | cut -d '=' -f 2 | \
  tr -d '"' | sed "s/$CUSER/root/")
CSSH_PRIP=$(cat $CVMID.txt | grep PRIVATE_IP | cut -d '=' -f 2 | \
  tr -d '"')

echo "Connection string: $CSSH_CON"
echo "Local IP: $CSSH_PRIP"
echo "Ansible VM created successfully!"

# Wait for SSH to be available
echo "Waiting for SSH service to be ready..."
sleep 20

# Export for use in project_start.sh
export CSSH_CON
export CVMID