# The Openstack modules:

## Introduction

The Openstack Puppet Modules are a flexible Puppet implementation
capable of configuring the core [Openstack](http://docs.openstack.org/) services:

  * [nova](http://nova.openstack.org/)     (compute service)
  * [glance](http://glance.openstack.org/)   (image database)
  * [swift](http://swift.openstack.org/)    (object store)
  * [keystone](http://keystone.openstack.org/) (authentication/authorization)
  * [horizon](http://horizon.openstack.org/)  (web front end)

A ['Puppet Module'](http://docs.puppetlabs.com/learning/modules1.html#modules) is a collection of related content that can be used to model
the configuration of a discrete service.

These modules are based on the adminstrative guides for openstack [compute](http://docs.openstack.org/essex/openstack-compute/admin/content/)
and [object store](http://docs.openstack.org/essex/openstack-object-storage/admin/content/)

## Dependencies:

### Puppet:

  * [Puppet](http://docs.puppetlabs.com/puppet/) 2.7.12 or greater
  * [Facter](http://www.puppetlabs.com/puppet/related-projects/facter/) 1.6.1 or greater (versions that support the osfamily fact)

### Platforms:

  These modules have been fully tested on Ubuntu Precise and Debian (Squeeze).

  For instructions of how to use these modules on Debian, check
  out this excellent [link](http://wiki.debian.org/OpenStackPuppetHowto):

  The instuctions in this document have only been verified on Ubuntu Precise.

### Network:

  Each of the machines running the Openstack services should have a minimum of 2 NICS.

  * One for the public/internal network
      - This nic should be assigned an IP address
  * One of the virtual machine network
      - This nic should not have an ipaddress assigned

  If machines only have one NIC, it is necessary to manually create a bridge
  called br100 that bridges into the ip address specified on that NIC

### Volumes:

  Every node that is configured to be a nova volume service needs to have a
  volume group called `nova-volumes`.

### Compute nodes

  Compute nodes should be deployed onto physical hardware.

  If compute nodes are deployed on virtual machines for testing,
  the libvirt_type should be configured as 'qemu'.

    class { 'openstack::compute':
      ...
      libvirt_type => 'qemu'
      ...
    }

## Installation

### Install Puppet

  * Puppet should be installed on all nodes:

    `apt-get install puppet`

  * A Puppet master is not required for all-in-one installations. It is,
    however, recommended for multi-node installations.

    * To install the puppetmaster:

      `apt-get install puppetmaster`

    * Rake and Git should be installed on the Puppet Master:

      `apt-get install rake git`

    * Some features of the modules require [storeconfigs](http://projects.puppetlabs.com/projects/1/wiki/Using_Stored_Configuration) to be enabled on the Puppet Master.

    * A site manifest site.pp should be created on the master:

            cat > /etc/puppet/manifests/site.pp << EOT
            node default {
              notify { 'I can connect!': }
            }
            EOT

    * The puppetmaster service should be restarted

      `service puppetmaster restart`

    * Each client should be enabled to use pluginsync and configured to connect
      to the master. The following lines should be configure in
      /etc/puppet/puppet.conf:

            [agent]
             pluginsync = true
             server     = <CONTROLLER_HOSTNAME>

    * Each agent should connect to the master:

      `puppet agent -t --waitforcert 60`

    * The certificate of each agent should be manually signed:

      `puppet cert sign <CERTNAME>`

### Install the Openstack modules

  * The Openstack modules should be installed into the module path of your master
    or on each node (if you are running puppet apply).

    Modulepath:
      * open source puppet - /etc/puppet/modules
      * Puppet Enterprise - /etc/puppetlabs/puppet/modules

  * To install the released versions from the forge:

      `puppet module install puppetlabs-openstack`

  * To install the latest revision of the modules from source (for developers/contributors):

        cd <module_path>
        git clone git://github.com/puppetlabs/puppetlabs-openstack openstack
        cd openstack
        rake modules:clone

## puppetlabs-openstack

The 'puppetlabs-openstack' module was written for those who want to get up and
going with a single or multi-node Openstack deployment as quickly as possible.
It provides a simple way of deploying Openstack that is based on
best practices shaped by companies that contributed to the design of these
modules.

### Classes

####  openstack::all

The openstack::all class provides a single configuration interface that can
be used to deploy an Openstack all-in-one node.

This is a great starting place for people who are just kicking the tires with
Openstack or with Puppet deployed OpenStack environments.

##### Usage Example:

  An openstack all in one class can be configured as follows:

    class { 'openstack::all':
      public_address       => '192.168.1.12',
      public_interface     => 'eth0',
      private_interface    => 'eth1',
      admin_email          => 'some_admin@some_company',
      admin_password       => 'admin_password',
      keystone_admin_token => 'keystone_admin_token',
      nova_user_password   => 'nova_user_password',
      glance_user_password => 'glance_user_password',
      rabbit_password      => 'rabbit_password',
      rabbit_user          => 'rabbit_user',
      libvirt_type         => 'kvm',
      fixed_range          => '10.0.0.0/24',
    }

  For more information on the parameters, check out the inline documentation
  in the manifest:

    <module_path>/openstack/manifests/all.pp

#### openstack::controller

The openstack::controller class is intended to provide basic support for
multi-node Openstack deployments.

There are two roles in this basic multi-node Openstack deployment:
  * controller - deploys all of the central management services
  * compute    - deploys the actual hypervisor on which VMs are deployed.

The openstack::controller class deploys the following Openstack services:
  * keystone
  * horizon
  * glance
  * nova (ommitting the nova compute service and nova network when multi_host is enabled)
  * mysql
  * rabbitmq

##### Usage Example:

  An openstack controller class can be configured as follows:

    class { 'openstack::controller':
      public_address          => '192.168.101.10',
      public_interface        => 'eth0',
      private_interface       => 'eth1',
      internal_address        => '192.168.101.10',
      floating_range          => '192.168.101.64/28',
      fixed_range             => '10.0.0.0/24',
      multi_host              => false,
      network_manager         => 'nova.network.manager.FlatDHCPManager',
      admin_email             => 'admin_email',
      admin_password          => 'admin_password',
      keystone_admin_token    => 'keystone_admin_token',
      glance_user_password    => 'glance_user_password',
      nova_user_password      => 'nova_user_password',
      rabbit_password         => 'rabbit_password',
      rabbit_user             => 'rabbit_user',
    }

  For more information on the parameters, check out the inline documentation
  in the manifest:

    <module_path>/openstack/manifests/controller.pp

#### openstack::compute

The Openstack compute role is used to manage the underlying hypervisor.
A typical multi-host Openstack installation would consist of a single
openstack::controller node and multiple openstack::compute nodes
(based on the amount of resources being virtualized)

The openstack::compute class deploys the following services:
  * nova
      - compute service (libvirt backend)
      - optionally, the nova network service (if multi_host is enabled)
      - optionally, the nova api service (if multi_host is enabled)
      - optionally, the nova volume service if it is enabled

##### Usage Example:

  An openstack compute class can be configured as follows:

    class { 'openstack::compute':
      private_interface  => 'eth1',
      internal_address   => $ipaddress_eth0,
      libvirt_type       => 'kvm',
      fixed_range        => '10.0.0.0/24',
      network_manager    => 'nova.network.manager.FlatDHCPManager',
      multi_host         => false,
      sql_connection     => 'mysql://nova:nova_db_passwd@192.168.101.10/nova',
      rabbit_host        => '192.168.101.10',
      glance_api_servers => '192.168.101.10:9292',
      vncproxy_host      => '192.168.101.10',
      vnc_enabled        => true,
      manage_volumes     => true,
    }

  For more information on the parameters, check out the inline documentation
  in the manifest:

    <module_path>/openstack/manifests/compute.pp

### Creating your deployment scenario

So far, classes have just been mentioned as configuration interfaces
used to deploy the openstack roles. The next section explains how to
apply these class definitions as roles to nodes using a site manifest.

The default file name for the site manifest is site.pp.

The site manifest should be contained in the master's manifestdir:

Manifestdir:
* open source puppet - /etc/puppet/manifests
* Puppet Enterprise - /etc/puppetlabs/puppet/manifests

Node blocks are used to map a node's certificate name to the classes
that should be assigned to it.

[Node blocks](http://docs.puppetlabs.com/guides/language_guide.html#nodes)
can match specific hosts:

    node my_explicit_host {...}

Or they can use regular expression to match sets of hosts

    node /my_similar_hosts/ {...}

Inside the site.pp file, Puppet resources declared within node blocks
are applied to those specified nodes. Resources specified at top-scope
are applied to all nodes.

### Deploying Openstack all-in-one environments

The easiest way to get started with the openstack::all class is to use the file

    <module_dir>/openstack/examples/site.pp

There is a node entry for

    node /openstack_all/ {...}

that can be used to deploy a simple nova all-in-one environment.

You can explicitly target this node entry by specifying a matching certname
and targeting the manifest explicitly with:

    puppet apply /etc/puppet/modules/openstack/examples/site.pp --certname openstack_all

You could also update the node name from site.pp to be the hostname of the
node on which you wish to perform an all-in-one installation.

    node /<my_node>/ {...}

In order to use manifests on a remote Puppet Master, you can run the following
command:

    puppet agent -td

### Using multi-node example

A Puppet Master should be used when deploying multi-node environments.

The example modules and site.pp should be installed on the Master.

This file contains entries for:

    node /openstack_controller/ {...}

    node /openstack_compute/ {...}

Which can be used to assign the respective roles.

(As above, you can replace these default certificate names with the hostname
of your nodes)

The first step for building out a multi-node deployment scenario is to choose
the IP address of the controller node.

Both nodes will need this configuration parameter.

In the example site.pp, replace the following line:

    $controller_node_address = <your_node_ip>

with the IP address of your controller.

It is also possible to use store configs in order for the compute hosts to
automatically discover the address of the controller host. Documentation
for this may not be available until a later release of the openstack modules.

Once everything is configured on the master, you can configure the nodes using:

    puppet agent -t <--certname ROLE_CERTNAME>

It is recommended that you first configure the controller before configuring
your compute nodes:

    openstack_controller> puppet agent -t --certname openstack_controller
    openstack_compute1>   puppet agent -t --certname openstack_compute1
    openstack_compute2>   puppet agent -t --certname openstack_compute2

## Verifying an OpenStack deployment

Once you have installed openstack using Puppet (and assuming you experience
no errors), the next step is to verify the installation:

### openstack::auth_file

The optionstack::auth_file class creates the file:

    /root/openrc

which stores environment variables that can be used for authentication
of openstack command line utilities.

#### Usage Example:

    class { 'openstack::auth_file':
      admin_password       => 'my_admin_password',
      controller_node      => 'my_controller_node',
      keystone_admin_token => 'my_admin_token',
    }

### Verification Process

  1. Ensure that your authentication information is stored in /root/openrc.
  This assumes that the class openstack::auth_file had been applied to this
  node.
  2. Ensure that your authenthication information is in the user's environment.

        source /root/openrc

  3. Verify that all of the services for nova are operational:

        > nova-manage service list
        Binary           Host          Zone   Status     State Updated_At
        nova-volume      <your_host>   nova   enabled    :-)   2012-06-06 22:30:05
        nova-consoleauth <your_host>   nova   enabled    :-)   2012-06-06 22:30:04
        nova-scheduler   <your_host>   nova   enabled    :-)   2012-06-06 22:30:05
        nova-compute     <your_host>   nova   enabled    :-)   2012-06-06 22:30:02
        nova-network     <your_host>   nova   enabled    :-)   2012-06-06 22:30:07
        nova-cert        <your_host>   nova   enabled    :-)   2012-06-06 22:30:04

  4. Ensure that the test script has been deployed to the node.

        file { '/tmp/test_nova.sh':
          source => 'puppet:///modules/openstack/nova_test.sh',
        }

  5. Run the test script.

        bash /tmp/test_nova.sh

    This script will verify that an image can be inserted into glance, and that
    that image can be used to fire up a virtual machine instance.

  6. Log into horizon on port 80 of your controller node and walk through a
     few operations:

  - fire up a VM
  - create a volume
  - attach that volume to the VM
  - allocate a floating IP address to a VM instance.
  - verify that voluem is actually attached to the VM and that
    it is reachable by its floating ip address (which will require
    some security groups)

## Building your own custom deployment scenario for Openstack

The classes that we have discussed from the Openstack module are themselves
composed from a large collection of modules that can be used to implement
customized openstack deployments.

A list and location of the source code for all modules used by the
puppetlabs-openstack module can be found in the following config file:

    other_repos.yaml

These building block modules have been written to support a wide variety of specific
configuration and deployment use cases. They also provide a lot of configuration
options not available with the more constrained puppetlabs-openstack modules.

The manifests in the Openstack module can serve as an example of how to use
these base building block to compose custom deployments.

    <module_path>/openstack/manifests/{all,controller,compute}.pp

These files contain examples of how to deploy the following services:

* nova
  * api
  * scheduler
  * volumes
  * compute
  * network
* keystone
* glance
  * api
  * registry
* horizon
* database
  * examples only exist for Mysql and Sqlite (there is work underway for postgresql)
* message queue
  * examples currently only exist for rabbitmq

Once you have selected which services need to be combined on which nodes, you should
review the modules for all of these services and figure out how you can configure
things like the pipelines and back-ends for these individual services.

This information should then be used to compose your own custom site.pp

## Deploying swift

In order to deploy swift, you should use the example manifest that comes with the
swift modules (examples/site.pp)

In this example, the following nodes are specified:

* swift_proxy
  - used as the ringbuilder + proxy node
* swift_storage_1
  - used as a storage node
* swift_storage_2
  - used as a storage node
* swift_storage_3
  - used as a storage node

This swift configuration requires both a Puppet Master as well as
storeconfigs to be enabled.

To fully configure an environment, the nodes must be configured in the following order:

* First the storage nodes need to be configured, this creates the storage services
  (object, container, account) and exports all of the storage endpoints for the ring
  builder into storeconfigs. (The replicator service fails to start in this initial
  configuration)
* Next, the ringbuild and swift proxy must be configured. The ringbuilder needs to
  collect the storage endpoints and create the ring database before the proxy can be
  installed. It also sets up an rsync server which is used to host the ring database.
  Resources are exported that are used to rsync the ring database from this server.
* Finally, the storage nodes should be run again so that they can rsync the ring
  databases.

This configuration of rsync create two loopback devices on every node. For more realistic
scenarios, users should deploy their own volumes in combination with the other classes.

Better examples of this should exist in the next version of these modules.

## Participating

Need a feature? Found a bug? Let me know!

We are extremely interested in growing a community of OpenStack experts and users
around these modules. so they can serve as an example of consolidated
best practices of how to deploy openstack.

The best way to get help with this set of modules is to email the group associated
with this project:

  puppet-openstack@puppetlabs.com

Issues should be opened here:

  https://projects.puppetlabs.com/projects/openstack

The process for contributing code is as follows:

* fork the projects in github
* submit pull requests to the projects containing code contributions
    - rspec tests are preferred but not required with initial pull requests.
      I am happy to work with folks to help them get then up and going with
      rspec-puppet.

## Future features:

  efforts are underway to implement the following additional features:

  * Validate module on Fedora 17 and RHEL
  * monitoring (basic system and Openstack application monitoring support
    with Nagios/Ganglia)
      - sensu is also being considered
  * Redundancy/HA - implementation of modules to support Highly available and
    redundant Openstack deployment.
  * These modules are currently intended to be classified and data-fied in a
    site.pp. Starting in version 3.0, it is possible to populate class
    parameters explicitly using puppet data bindings (which use hiera as the
    back-end). The decision not to use hiera was primarily based on the fact
    that it requires explicit function calls in 2.7.x)
  * implement provisioning automation that can be used to fully provision
    an entire environment from scratch
  * Implement PuppetDB to allow service auto-discovery to simplify the
    configuration of service association
