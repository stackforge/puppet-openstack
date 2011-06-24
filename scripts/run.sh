#!/bin/bash
puppet apply /vagrant/manifests/hosts.pp
puppet apply /vagrant/manifests/site.pp --modulepath /vagrant/modules --graph --certname $* --graphdir /vagrant/graphs
