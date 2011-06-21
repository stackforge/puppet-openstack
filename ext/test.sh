# Extract creds
cd ~
sudo nova-manage project zipfile nova novaadmin
unzip nova.zip
source novarc
euca-add-keypair openstack > ~/cert.pem

# Add images to glance and index
glance add name=ramdisk disk_format=ari container_format=ari is_public=True < /vagrant/images/lucid_ami/initrd.img-2.6.32-23-server
glance add name=kernel disk_format=aki container_format=aki is_public=True < /vagrant/images/lucid_ami/vmlinuz-2.6.32-23-server
glance add name=lucid_ami disk_format=ami container_format=ami is_public=True ramdisk_id=1 kernel_id=2 < /vagrant/images/lucid_ami/ubuntu-lucid.img
glance index

# List 
nova flavor-list
nova image-list

# Run instance
euca-run-instances ami-00000003 -k openstack -t m1.tiny
euca-describe-instances

echo 'check the status of your VM with euca-describe-instances'
echo 'when it is in the running state, verify that you can login'
echo 'using ssh -i ~/cert.pem root@ip.address'
