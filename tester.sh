#!/bin/bash

cd ~/.ansible

ansible all -m ping -v

echo "Gathering facts from all hosts: "
ansible all -m setup -a "filter=ansible_distribution*"
echo ""
echo "Checking disk space on all hosts: "
ansible all -m shell -a "df -h /"
echo ""
