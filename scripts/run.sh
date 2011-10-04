#!/bin/bash
puppet apply /vagrant/manifests/hosts.pp --modulepath /vagrant/modules
puppet apply /vagrant/manifests/site.pp --modulepath /vagrant/modules --graph --certname $* --graphdir /vagrant/graphs
