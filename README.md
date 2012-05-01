# NOTE

This project has been completely rewritten to manage
all of the dependent modules based on a rake task.

If you are looking for the old project that managed the openstack
modules based on submodules, it has been moved to here:

  https://github.com/puppetlabs/puppetlabs-openstack_project


# Puppet Module for Openstack

This module wraps the various other openstack modules and
provides higher level classes that can be used to deploy
openstack environments.

## Supported Versions

These modules are currently specific to the Essex release of OpenStack.

They have been tested and are known to work on Ubuntu 12.04 (Precise)

They are also in the process of being verified against Fedora 17.

## Installation:

1. Install Puppet

  $ apt-get install puppet

2. Install other project dependencies:

  $ apt-get install rake git

3. Download the Puppet OpenStack module

  $ cd ~ && git clone git://github.com/puppetlabs/puppetlabs-openstack.git

4. Copy the module into the modulepath

  $ sudo cp -R ~/puppetlabs-openstack/modules/* /etc/puppet/modules/

5. Use the rake task to install all other module dependencies:

<pre>
  rake modules:clone_all
</pre>

This rake task is driven by the following configuration file:

<pre>
  other_repos.yaml
</pre>

## Classes

This module currently provides 3 classes that can be used to deploy openstack.

openstack::all - can be used to deploy a single node all in one environemnt

openstack::controller - can be used to deploy an openstack controller

openstack::compute - can be used to deploy an openstack compute node.

## Example Usage

coming soon...
