# Hospital Management System

A comprehensive hospital management system deployed using OpenNebula, Ansible, and Docker.

## Project Structure

```
project/
├── project_start.sh          # Main deployment script
├── ansible_vm/               # Scripts for creating and bootstrapping ansible-vm
│   ├── ansible_vm.sh
│   ├── bootstrap_ansible.sh
│   ├── create_db_vm.sh
│   ├── create_webserver_vm.sh
│   └── create_client_vm.sh
├── ansible_config/           # Ansible playbooks and configuration
│   ├── inventory.yml
│   ├── ansible.cfg
│   ├── create_vms.yml
│   ├── configure_all.yml
│   ├── db_setup.yml
│   ├── webserver_setup.yml
│   └── client_setup.yml
├── docker/                   # Docker LAMP stack configuration
│   ├── Dockerfile            # Uses lamp_install.sh from UNIX course
│   ├── lamp_install.sh       # LAMP installation script
│   └── docker-compose.yml
├── hospital_app/             # Hospital application
│   ├── public/               # Web-accessible PHP files
│   ├── db/                   # Database schema
│   └── config/               # Configuration files
└── config/                   # Project configuration
    └── team_members.conf     # Team member OpenNebula accounts
```

## Requirements

1. **Virtual Machines (OpenNebula)**:
   - ansible-vm: Ansible control node (Team Member 1)
   - db-vm: MySQL database server (Team Member 2)
   - webserver-vm: Web server with Docker LAMP (Team Member 3)
   - client-vm: Client machine with browser (Team Member 4)

2. **Hospital Functionality**:
   - Patient registration and login
   - Doctor registration and login
   - Appointment booking and management
   - Patient medical records
   - Doctor search (by name, surname, specialization)
   - Doctor work schedule with Google Calendar integration
   - Patient card view

3. **Deployment**:
   - All VMs created via OpenNebula (one per team member)
   - All configuration via Ansible playbooks
   - LAMP stack in Docker using custom installation script
   - All machines communicate with each other

## Setup

1. **Configure Team Members**:
   Edit `config/team_members.conf` with your team's OpenNebula usernames and endpoints.

2. **Run Deployment**:
   ```bash
   bash project_start.sh
   ```

3. **Access Application**:
   After deployment, access the hospital system at: `http://<webserver-vm-ip>`

## Features

### Patient Features
- Register and login
- Book appointments with doctors
- View medical records
- Search for doctors by name or specialization
- Cancel appointments

### Doctor Features
- Register and login
- View appointment schedule
- Manage appointments
- Google Calendar integration
- Complete appointments

## Technical Details

- **OS**: All VMs run Linux (Ubuntu 24.04)
- **Database**: MySQL
- **Web Server**: Apache in Docker container
- **Application**: PHP with MySQL
- **Configuration**: Ansible playbooks
- **Container**: Custom Docker image using lamp_install.sh script

