#!/bin/bash
# Extract creds
cd ~
sudo nova-manage project zipfile nova novaadmin
unzip nova.zip
source novarc
euca-add-keypair openstack > ~/cert.pem
# List
nova flavor-list
nova image-list

# Run instance
euca-run-instances ami-00000003 -k openstack -t m1.tiny
euca-describe-instances

echo 'log into your controller VM'
echo 'check the status of your VM with euca-describe-instances'
echo 'when it is in the running state, verify that you can login'
echo 'using ssh -i ~/cert.pem root@ip.address'
