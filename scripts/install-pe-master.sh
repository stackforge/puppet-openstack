#!/bin/bash
puppet apply /vagrant/manifests/hosts.pp --modulepath /vagrant/modules --debug
curl https://s3.amazonaws.com/pe-builds/released/2.0.1/puppet-enterprise-2.0.1-el-6-i386.tar.gz 
