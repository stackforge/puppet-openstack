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
$rabbit_password      = 'openstack_rabbit_password',
$rabbit_user          = 'openstack_rabbit_user',
$fixed_network_range  = '10.0.0.0/24'
# switch this to true to have all service log at verbose
$verbose              = 'false',


#### end shared variables #################

# all nodes whose certname matches openstack_all should be
# deployed as all-in-one openstack installations.
node /openstack_all/ {

  class { 'openstack::all':
    public_address       => $ipaddress_eth0,
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
    rabbit_password      => $rabbit_password,
    rabbit_user          => $rabbit_user,
    libvirt_type         => 'kvm',
    fixed_range          => $fixed_network_range,
    verbose              => $verbose,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => '127.0.0.1',
  }

}

# multi-node specific parameters

$controller_node_address  = '192.168.101.11'

$controller_node_public   = $controller_node_address
$controller_node_internal = $controller_node_address 

node /openstack_controller/ {

#  class { 'nova::volume': enabled => true }

#  class { 'nova::volume::iscsi': }

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => '192.168.101.64/28',
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => false,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    mysql_root_password     => $mysql_root_password,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    export_resources        => false,
  }

}

node /openstack_compute/ {

  class { 'openstack::compute':
    internal_address => $ipaddress,
    libvirt_type     => 'kvm',
  }

}

