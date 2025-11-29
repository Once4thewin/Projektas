#!/bin/bash

sudo apt update -y
sudo apt install -y ansible jq
ansible --version

cd ~/.ansible

ansible-galaxy collection install community.general --force

# Create playbook to provision VMs
cat > create_vms.yml << "EOF"
- name: Create OpenNebula VMs
  become: yes
  hosts: localhost
  collections:
    - community.general
  tasks:
    - name: Install python packages
      apt:
        name:
          - python3
          - python3-pip
          - python3-venv
          - build-essential
        state: present

    - name: Install pyone and oca
      pip:
        name:
          - pyone
          - oca
        state: present
        extra_args: --break-system-packages

    - name: Create webserver vm
      community.general.one_vm:
        api_url: "https://grid5.mif.vu.lt/cloud3/RPC2"
        api_username: "joda0846"
        api_password: "Joris123."
        template_name: "ubuntu-24.04"
        attributes:
          name: "webserver-vm"
        state: present
      register: webserver_result

    - name: Create db vm
      community.general.one_vm:
        api_url: "https://grid5.mif.vu.lt/cloud3/RPC2"
        api_username: "tili1267"
        api_password: "Ltu120320#"
        template_name: "ubuntu-24.04"
        attributes:
          name: "db-vm"
        state: present
      register: db_result

    - name: Create client vm
      community.general.one_vm:
        api_url: "https://grid5.mif.vu.lt/cloud3/RPC2"
        api_username: "tili1267"
        api_password: "Ltu120320#"
        template_name: "ubuntu-24.04"
        attributes:
          name: "client-vm"
        state: present
      register: client_result

    - name: Save VM IDs to file
      copy:
        content: |
          WEBSERVER_ID={{ webserver_result.instances_ids[0] }}
          DB_ID={{ db_result.instances_ids[0] }}
          CLIENT_ID={{ client_result.instances_ids[0] }}
        dest: /root/vm_ids.txt
EOF

# Run the playbook to create VMs
ansible-playbook create_vms.yml

echo "VMs created, waiting for them to start..."

# Source the VM IDs
source /root/vm_ids.txt

# Function to check VM state and get IP
get_vm_info() {
    local vm_id=$1
    local username=$2
    local password=$3
    local endpoint="https://grid5.mif.vu.lt/cloud3/RPC2"
    
    # Get VM info using onevm show
    onevm show "$vm_id" --user "$username" --password "$password" \
      --endpoint "$endpoint" --json 2>/dev/null
}

# Function to extract IP from VM info
extract_ip() {
    local vm_json=$1
    echo "$vm_json" | jq -r '.VM.TEMPLATE.NIC[0].IP // empty'
}

# Function to check if VM is running
check_vm_running() {
    local vm_json=$1
    local state=$(echo "$vm_json" | jq -r '.VM.STATE // empty')
    local lcm_state=$(echo "$vm_json" | jq -r '.VM.LCM_STATE // empty')
    
    # State 3 = ACTIVE, LCM_STATE 3 = RUNNING
    if [ "$state" == "3" ] && [ "$lcm_state" == "3" ]; then
        return 0
    else
        return 1
    fi
}

# Wait for VMs to be running and get their IPs
echo "Waiting for webserver-vm to be running..."
WEBSERVER_IP=""
for i in {1..60}; do
    VM_INFO=$(get_vm_info "$WEBSERVER_ID" "joda0846" "Joris123.")
    if check_vm_running "$VM_INFO"; then
        WEBSERVER_IP=$(extract_ip "$VM_INFO")
        if [ -n "$WEBSERVER_IP" ]; then
            echo "Webserver VM is running with IP: $WEBSERVER_IP"
            break
        fi
    fi
    echo "Attempt $i/60: Webserver not ready yet..."
    sleep 10
done

echo "Waiting for db-vm to be running..."
DB_IP=""
for i in {1..60}; do
    VM_INFO=$(get_vm_info "$DB_ID" "tili1267" "Ltu120320#")
    if check_vm_running "$VM_INFO"; then
        DB_IP=$(extract_ip "$VM_INFO")
        if [ -n "$DB_IP" ]; then
            echo "Database VM is running with IP: $DB_IP"
            break
        fi
    fi
    echo "Attempt $i/60: Database not ready yet..."
    sleep 10
done

echo "Waiting for client-vm to be running..."
CLIENT_IP=""
for i in {1..60}; do
    VM_INFO=$(get_vm_info "$CLIENT_ID" "tili1267" "Ltu120320#")
    if check_vm_running "$VM_INFO"; then
        CLIENT_IP=$(extract_ip "$VM_INFO")
        if [ -n "$CLIENT_IP" ]; then
            echo "Client VM is running with IP: $CLIENT_IP"
            break
        fi
    fi
    echo "Attempt $i/60: Client not ready yet..."
    sleep 10
done

# Verify all IPs were obtained
if [ -z "$WEBSERVER_IP" ] || [ -z "$DB_IP" ] || [ -z "$CLIENT_IP" ]; then
    echo "ERROR: Failed to obtain all VM IPs"
    echo "Webserver IP: ${WEBSERVER_IP:-NOT FOUND}"
    echo "Database IP: ${DB_IP:-NOT FOUND}"
    echo "Client IP: ${CLIENT_IP:-NOT FOUND}"
    exit 1
fi

# Generate Ansible inventory file
cat > /root/.ansible/inventory.ini << EOF
[webserver]
webserver-vm ansible_host=$WEBSERVER_IP ansible_user=root ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[database]
db-vm ansible_host=$DB_IP ansible_user=root ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[client]
client-vm ansible_host=$CLIENT_IP ansible_user=root ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=/root/.ssh/id_rsa
db_password=SecurePassword123
EOF

echo "Inventory file generated at /root/.ansible/inventory.ini"
cat /root/.ansible/inventory.ini

# Generate ansible.cfg
cat > /root/.ansible/ansible.cfg << EOF
[defaults]
inventory = /root/.ansible/inventory.ini
host_key_checking = False
remote_user = root
private_key_file = /root/.ssh/id_rsa
timeout = 30
retry_files_enabled = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
pipelining = True
EOF

echo "Ansible configuration created at /root/.ansible/ansible.cfg"

# Wait additional time for SSH to be available
echo "Waiting for SSH to be available on all VMs..."
sleep 30

# Test connectivity and distribute SSH keys
cat > /root/.ansible/setup_ssh.yml << "EOF"
---
- name: Setup SSH connectivity
  hosts: all
  gather_facts: no
  tasks:
    - name: Wait for SSH to be available
      wait_for_connection:
        timeout: 300
        delay: 10
      
    - name: Gather facts
      setup:

    - name: Ensure .ssh directory exists
      file:
        path: /root/.ssh
        state: directory
        mode: '0700'

    - name: Add ansible-vm SSH public key to authorized_keys
      authorized_key:
        user: root
        state: present
        key: "{{ lookup('file', '/root/.ssh/id_rsa.pub') }}"

    - name: Test Python availability
      command: python3 --version
      register: python_version
      
    - name: Display Python version
      debug:
        msg: "Python version on {{ inventory_hostname }}: {{ python_version.stdout }}"
EOF

echo "Setting up SSH connectivity to all VMs..."
ansible-playbook /root/.ansible/setup_ssh.yml

# Test connectivity
echo "Testing Ansible connectivity to all hosts..."
ansible all -m ping

echo "All VMs are created, running, and accessible via Ansible!"
echo ""
echo "VM Information:"
echo "==============="
echo "Webserver VM: $WEBSERVER_IP (ID: $WEBSERVER_ID)"
echo "Database VM: $DB_IP (ID: $DB_ID)"
echo "Client VM: $CLIENT_IP (ID: $CLIENT_ID)"
echo ""
echo "You can now run configuration playbooks!"