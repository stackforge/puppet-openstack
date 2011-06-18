cd ~
sudo nova-manage project zipfile nova novaadmin
unzip nova.zip
source novarc
glance add name=ramdisk disk_format=ari container_format=ari is_public=True < /vagrant/images/lucid_ami/initrd.img-2.6.32-23-server
glance add name=kernel disk_format=aki container_format=aki is_public=True < /vagrant/images/lucid_ami/vmlinuz-2.6.32-23-server
glance add name=lucid_ami disk_format=ami container_format=ami is_public=True ramdisk_id=1 kernel_id=2 < ubuntu-lucid.img
glance index
nova flavor-list
nova image-list
nova boot test --flavor 1 --image 3
euca-describe-instances
