#!/bin/bash
#
# assumes that resonable credentials have been stored at
# /root/auth
source /root/auth

# get an image to test with
#wget http://uec-images.ubuntu.com/releases/11.10/release/ubuntu-11.10-server-cloudimg-amd64-disk1.img

# import that image into glance
#glance add name="Ubuntu 11.10 cloudimg amd64" is_public=true container_format=ovf disk_format=qcow2 < ubuntu-11.10-server-cloudimg-amd64-disk1.img

#IMAGE_ID=`glance index | grep 'Ubuntu 11.10 cloudimg amd64' | head -1 |  awk -F' ' '{print $1}'`

wget https://launchpad.net/cirros/trunk/0.3.0/+download/cirros-0.3.0-x86_64-disk.img

glance add name='cirros image' is_public=true container_format=bare disk_format=qcow2 < cirros-0.3.0-x86_64-disk.img

IMAGE_ID=`glance index | grep 'cirros image' | head -1 |  awk -F' ' '{print $1}'`

# create a pub key
ssh-keygen -f /tmp/id_rsa -t rsa -N ''
nova keypair-add --pub_key /tmp/id_rsa.pub key1

nova boot --flavor 1 --image ${IMAGE_ID} --key_name key1 dans_vm

nova show dans_vm

# create ec2 credentials
keystone ec2-credentials-create
