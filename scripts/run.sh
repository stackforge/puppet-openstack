#!/bin/bash
puppet apply /vagrant/manifests/hosts.pp
puppet apply --certname $1 /vagrant/manifests/site.pp --modulepath /vagrant/modules
