#!/bin/bash

set -e

echo "Vykdoma vms_start.sh ansible VM viduje"

# Atnaujinam sistemą ir įdiegiame Ansible
sudo apt update -y
sudo apt install -y ansible python3-pip openssh-client -y

ansible --version

# Darbo katalogas Ansible dalykams
ANSIBLE_DIR="/opt/ansible"
sudo mkdir -p "$ANSIBLE_DIR"
cd "$ANSIBLE_DIR"

# Įdiegiame community.general ir community.docker kolekcijas
ansible-galaxy collection install community.general --force
ansible-galaxy collection install community.docker --force

# Sukuriame playbook'ą
sudo tee ymlkurimas.yml > /dev/null << "BMW"
- name: opennebula vm kurimas
  hosts: localhost
  become: yes
  collections:
    - community.general

  vars:
    api_url: "https://grid5.mif.vu.lt/cloud3/RPC2"
    work_dir: "/opt/ansible"

  tasks:
    - name: Įdiegiu reikiamus python paketus
      apt:
        name:
          - python3
          - python3-pip
          - python3-venv
          - build-essential
        state: present
        update_cache: yes

    - name: Įdiegiu pyone ir oca per pip
      pip:
        name:
          - pyone
          - oca
        state: present
        extra_args: --break-system-packages

    # ---- NAUJŲ VM KŪRIMAS ----

    - name: Sukuriu webserver vm
      community.general.one_vm:
        api_url: "{{ api_url }}"
        api_username: "joda0846"
        api_password: "Joris123."
        template_name: "ubuntu-24.04"
        attributes:
          name: "webserver vm"
        state: present
      register: web_vm

    - name: Sukuriu db vm
      community.general.one_vm:
        api_url: "{{ api_url }}"
        api_username: "tili1267"
        api_password: "Ltu120320#"
        template_name: "ubuntu-24.04"
        attributes:
          name: "db vm"
        state: present
      register: db_vm

    - name: Sukuriu client vm
      community.general.one_vm:
        api_url: "{{ api_url }}"
        api_username: "tili1267"
        api_password: "Ltu120320#"
        template_name: "ubuntu-24.04"
        attributes:
          name: "client vm"
        state: present
      register: client_vm

    # ---- DEBUGAS: Parodome VM struktūrą ----
    - name: Debug - parodyti web_vm struktūrą
      debug:
        var: web_vm
        verbosity: 0

    # ---- IP IŠ one_vm REZULTATŲ ----
    - name: Ištraukiu IP adresus
      set_fact:
        web_ip: >-
          {{ (web_vm.instances[0].networks
              | selectattr('ip', 'search', '^10\\.0\\.0\\.')
              | map(attribute='ip')
              | first)
             | default(web_vm.instances[0].networks[0].ip, true) }}
        db_ip: >-
          {{ (db_vm.instances[0].networks
              | selectattr('ip', 'search', '^10\\.0\\.0\\.')
              | map(attribute='ip')
              | first)
             | default(db_vm.instances[0].networks[0].ip, true) }}
        client_ip: >-
          {{ (client_vm.instances[0].networks
              | selectattr('ip', 'search', '^10\\.0\\.0\\.')
              | map(attribute='ip')
              | first)
             | default(client_vm.instances[0].networks[0].ip, true) }}

    - name: Parodyti surastus IP
      debug:
        msg:
          - "Webserver IP: {{ web_ip }}"
          - "Database IP: {{ db_ip }}"
          - "Client IP: {{ client_ip }}"

    # ---- GENERUOTI SSH RAKTĄ ----
    - name: Sukurti SSH raktą ansible konfigūracijai
      openssh_keypair:
        path: "{{ work_dir }}/ansible_key"
        type: rsa
        size: 4096
        state: present
        force: no
        mode: '0600'

    # ---- INVENTORY.INI GENERAVIMAS ----
    - name: Sugeneruoju inventory.ini
      copy:
        dest: "{{ work_dir }}/inventory.ini"
        mode: '0644'
        content: |
          [db]
          db-vm ansible_host={{ db_ip }}

          [webserver]
          webserver-vm ansible_host={{ web_ip }}

          [client]
          client-vm ansible_host={{ client_ip }}

          [all:vars]
          ansible_user=root
          ansible_ssh_private_key_file={{ work_dir }}/ansible_key
          ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

    - name: Sukurti ansible.cfg
      copy:
        dest: "{{ work_dir }}/ansible.cfg"
        mode: '0644'
        content: |
          [defaults]
          inventory = {{ work_dir }}/inventory.ini
          host_key_checking = False
          retry_files_enabled = False
          
          [ssh_connection]
          pipelining = True

    # ---- IŠSAUGOTI VM ID IR KITUS DUOMENIS ----
    - name: Išsaugoti VM informaciją
      copy:
        dest: "{{ work_dir }}/vm_info.txt"
        mode: '0644'
        content: |
          Webserver VM ID: {{ web_vm.instances[0].vm_id }}
          Webserver IP: {{ web_ip }}
          
          Database VM ID: {{ db_vm.instances[0].vm_id }}
          Database IP: {{ db_ip }}
          
          Client VM ID: {{ client_vm.instances[0].vm_id }}
          Client IP: {{ client_ip }}

    - name: Parodyti, kur failai sukurti
      debug:
        msg:
          - "Visi konfigūracijos failai sukurti {{ work_dir }} kataloge:"
          - "  - inventory.ini"
          - "  - ansible.cfg"
          - "  - ansible_key (SSH raktas)"
          - "  - vm_info.txt"
BMW

# Paleidžiam playbook'ą
echo "Paleidžiamas playbook..."
ansible-playbook ymlkurimas.yml

echo ""
echo "=========================================="
echo "Visi VM'ai sukurti!"
echo "=========================================="
echo ""

# Wait for VMs to be fully ready
echo "Laukiame kol VM'ai bus pilnai paruošti..."
sleep 30

# Test connection to all VMs
echo "Tikriname ryšį su VM'ais..."
cd "$ANSIBLE_DIR"
ansible all -m ping || {
    echo "Klaida: Nepavyko prisijungti prie VM'ų. Laukiame dar..."
    sleep 30
    ansible all -m ping
}

# Create playbooks directory structure
PLAYBOOKS_DIR="$ANSIBLE_DIR/playbooks"
sudo mkdir -p "$PLAYBOOKS_DIR"
cd "$PLAYBOOKS_DIR"

# Note: Docker files and playbooks should be copied to ansible-vm
# This can be done via SCP from the host machine or included in the VM image
# For now, we assume they will be available at the correct paths

echo ""
echo "=========================================="
echo "Įdiegiame Docker visuose VM'uose"
echo "=========================================="
echo ""

# Install Docker on all VMs
cd "$PLAYBOOKS_DIR"
ansible-playbook docker_setup.yml || {
    echo "Klaida: Nepavyko įdiegti Docker. Bandome dar kartą..."
    sleep 10
    ansible-playbook docker_setup.yml
}

echo ""
echo "=========================================="
echo "Kopijuojame Docker failus į VM'us"
echo "=========================================="
echo ""

# Note: Docker files need to be copied from the project directory
# This assumes the project is accessible from ansible-vm
# You may need to adjust paths based on how files are transferred

echo ""
echo "=========================================="
echo "Paleidžiame Docker konteinerius"
echo "=========================================="
echo ""

# Deploy database container first (webserver depends on it)
echo "Kuriu database konteinerį..."
cd "$PLAYBOOKS_DIR"
ansible-playbook database_deploy.yml

# Wait for database to be ready
echo "Laukiame kol duomenų bazė bus paruošta..."
sleep 20

# Deploy webserver container
echo "Kuriu webserver konteinerį..."
cd "$PLAYBOOKS_DIR"
ansible-playbook webserver_deploy.yml

# Deploy client browser container
echo "Kuriu client browser konteinerį..."
cd "$PLAYBOOKS_DIR"
ansible-playbook client_deploy.yml

echo ""
echo "=========================================="
echo "Visi Docker konteineriai paleisti!"
echo "=========================================="
echo ""
echo "Konfigūracijos failai yra: $ANSIBLE_DIR"
echo ""
echo "Norėdami patikrinti:"
echo "  ls -la $ANSIBLE_DIR"
echo ""
echo "Norėdami testuoti ryšį su VM:"
echo "  cd $ANSIBLE_DIR"
echo "  ansible all -m ping"
echo ""
echo "Norėdami patikrinti Docker konteinerius:"
echo "  ansible webserver -m shell -a 'docker ps'"
echo "  ansible db -m shell -a 'docker ps'"
echo "  ansible client -m shell -a 'docker ps'"
echo ""
echo "VM informacija:"
cat "$ANSIBLE_DIR/vm_info.txt" 2>/dev/null || echo "VM info failas dar nesukurtas"
echo ""