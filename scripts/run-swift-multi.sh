#!/bin/bash
apt-get update
puppet apply /vagrant/manifests/hosts.pp --modulepath /vagrant/modules --debug
puppet agent --server puppetmaster --certname $* --debug --trace --test --pluginsync true
