#!/bin/bash
puppet apply /vagrant/manifests/setup_agent.pp --modulepath /vagrant/modules --debug
puppet apply /vagrant/manifests/site.pp --modulepath /vagrant/modules --graph --certname $* --graphdir /vagrant/graphs --debug --trace
