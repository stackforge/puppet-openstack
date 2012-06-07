#
# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#

# deploy a script that can be used to test nova
file { '/tmp/test_nova.sh':
  source => 'puppet:///modules/openstack/nova_test.sh',
}

####### shared variables ##################


# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments

# assumes that eth0 is the public interface
$public_address    = $ipaddress_eth0
$public_interface  = 'eth0'
# assumes that eth1 is the interface that will be used for the vm network
# this configuration assumes this interface is active but does not have an
# ip address allocated to it. 
$private_interface = 'eth1'
# credentials
$admin_email          = 'root@localhost'
$admin_password       = 'keystone_admin'
$keystone_db_password = 'keystone_db_pass'
$keystone_admin_token = 'keystone_admin_token'
$nova_db_password     = 'nova_pass'
$nova_user_password   = 'nova_pass'
$glance_db_password   = 'glance_pass'
$glance_user_password = 'glance_pass'

#### end shared variables #################

# all nodes whose certname matches openstack_all should be
# deployed as all-in-one openstack installations.
node /openstack_all/ {

  class { 'openstack::all':
    public_address       => $public_address,
    public_interface     => $public_interface,
    private_interface    => $private_interface,
    admin_email          => $admin_email,
    admin_password       => $admin_password,
    keystone_db_password => $keystone_db_password,
    keystone_admin_token => $keystone_admin_token,
    nova_db_password     => $nova_db_password,
    nova_user_password   => $nova_user_password,
    glance_db_password   => $glance_db_password,
    glance_user_password => $glance_user_password,
    libvirt_type         => 'kvm',
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => '127.0.0.1',
  }

}

node /openstack_controller/ {

  class { 'openstack::controller':
    public_address   => $public_hostname,
    internal_address => $ipaddress,
  }

}

node /openstack_compute/ {

  class { 'openstack::compute':
    internal_address => $ipaddress,
    libvirt_type     => 'kvm',
  }

}

