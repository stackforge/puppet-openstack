#!/bin/bash
# TODO fix this, the image that I am using is broken
apt-get update
puppet apply /vagrant/manifests/hosts.pp --modulepath /vagrant/modules --debug
puppet apply /vagrant/modules/swift/examples/all.pp --modulepath /vagrant/modules --graph --certname $* --graphdir /vagrant/graphs --debug --trace
