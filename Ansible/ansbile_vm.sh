#!/bin/bash

wget -q -O- https://downloads.opennebula.org/repo/repo.key | sudo apt-key add -
echo "deb https://downloads.opennebula.org/repo/5.6/Ubuntu/18.04 stable opennebula" | sudo tee /etc/apt/sources.list.d/opennebula.list

sudo apt update -y
sudo apt install -y opennebula-tools

ssh-add
CUSER=pisa1147
CPASS=arnasvarnas12
CENDPOINT=https://grid5.mif.vu.lt/cloud3/RPC2
template="ubuntu-24.04"
VMname="ansible-project"
CVMREZ=$(onetemplate instantiate $template --name $VMname --user $CUSER --password $CPASS  --endpoint $CENDPOINT)
CVMID=$(echo $CVMREZ |cut -d ' ' -f 3)
echo $CVMID

echo "Laukiama kol ansible vm prades darba"
sleep 40

$(onevm show $CVMID  --user $CUSER --password $CPASS  --endpoint $CENDPOINT >$CVMID.txt)
CSSH_CON=$(cat $CVMID.txt | grep CONNECT\_INFO1| cut -d '=' -f 2 | tr -d '"'|sed 's/'$CUSER'/root/')
CSSH_PRIP=$(cat $CVMID.txt | grep PRIVATE\_IP| cut -d '=' -f 2 | tr -d '"')
echo "Connection string: $CSSH_CON"
echo "Local IP: $CSSH_PRIP"

echo "			ansible sukurtas..."