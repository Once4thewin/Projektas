#!/bin/bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$ROOT_DIR/Ansible"

chmod a+x "$ANSIBLE_DIR/ansible_vm.sh" "$ANSIBLE_DIR/vms_start.sh"

source "$ANSIBLE_DIR/ansible_vm.sh"


 $CSSH_CON  'bash -s' < "$ANSIBLE_DIR/vms_start.sh"
