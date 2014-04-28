#
# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#

# deploy a script that can be used to test nova
class { 'openstack::test_file': }

####### shared variables ##################

# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments

# Controller public and private interface
$controller_pub_interface = 'eth0'
$controller_pri_interface = 'eth1'

# Compute public and private interface
$compute_pub_interface = 'eth0'
$compute_pri_interface = 'eth2'

# Fully qualified domain name to access horizon
$horizon_fqdn            = '*.plumgrid.com'

# credentials
$admin_tenant            = 'admin'
$admin_email             = 'root@localhost'
$admin_password          = 'nova'
$mysql_root_password     = 'nova'
$cinder_user_password    = 'cinder_pass'
$cinder_db_password      = 'cinder_pass'
$keystone_db_password    = 'keystone_db_pass'
$keystone_admin_token    = 'keystone_admin_token'
$nova_db_password        = 'nova_pass'
$nova_user_password      = 'nova_pass'
$glance_db_password      = 'glance_pass'
$glance_user_password    = 'glance_pass'
$rabbit_password         = 'rabbit_pass'
$rabbit_user             = 'rabbit_user'
$secret_key              = 'secret_key'
$mysql_root_password     = 'secret'
# switch this to true to have all service log at verbose
$verbose                 = false

# Controller IP address
$controller_node_address  = '192.168.1.146'
$controller_node_public   = $controller_node_address
$controller_node_internal = $controller_node_address

# Computer IP address
$compute_node_address      = '192.168.1.151'

# Neutron configuration 
$neutron_user_password   = 'neutron_user_password'
$neutron_db_password     = 'neutron_db_password'

# Plumgrid plugin configuration
$neutron_core_plugin     = 'neutron.plugins.plumgrid.plumgrid_plugin.plumgrid_plugin.NeutronPluginPLUMgridV2'
$pg_director_server      = "192.168.1.145"
$pg_director_server_port = "443"
$pg_username             = "plumgrid"
$pg_password             = "plumgrid"
$pg_servertimeout        = "70"

#### end shared variables #################

# all nodes whose certname matches openstack_all should be
# deployed as all-in-one openstack installations.
node /openstack_all/ {

  include 'apache'
  class { 'openstack::all':
    public_address          => $ipaddress_eth0,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    cinder_db_password      => $cinder_db_password,
    cinder_user_password    => $cinder_user_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    libvirt_type            => 'kvm',
    verbose                 => $verbose,
    secret_key              => $secret_key,
    neutron                 => false,
    mysql_root_password     => $mysql_root_password,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => '127.0.0.1',
  }

}

# multi-node specific parameters
node /controller/ {

#  class { 'nova::volume': enabled => true }

#  class { 'nova::volume::iscsi': }

  class { 'openstack::controller':
    # controller address and interface
    public_address          => $controller_node_public,
    public_interface        => $controller_pub_interface,
    private_interface       => $controller_pub_interface,
    internal_address        => $controller_node_internal,
    fqdn                    => $horizon_fqdn,
    # by default it does not enable multi-host mode
    multi_host              => true,
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    # MySQL
    mysql_root_password     => $mysql_root_password,
    # Admin credentials
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    # Keystone
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    # Cinder
    cinder_db_password      => $cinder_db_password,
    cinder_user_password    => $cinder_user_password,
    # Glance
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    # Neutron
    ovs_enable_tunneling    => false,
    external_bridge_name    => undef,
    enable_ovs_agent        => false,
    enable_dhcp_agent       => false,
    enable_l3_agent         => false,
    enable_metadata_agent   => false,
    neutron                 => true,
    neutron_user_password   => $neutron_user_password,
    neutron_db_password     => $neutron_db_password,
    neutron_core_plugin     => $neutron_core_plugin,
    security_group_api      => 'nova',
    pg_director_server      => $pg_director_server,
    pg_director_server_port => $pg_director_server_port,
    pg_username             => $pg_username,
    pg_password             => $pg_password,
    pg_servertimeout        => $pg_servertimeout,
    metadata_shared_secret  => true,
    # Nova
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    # Rabbit
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    secret_key              => $secret_key,
  }

  class { 'openstack::auth_file':
    admin_password          => $admin_password,
    admin_tenant            => $admin_tenant,
    keystone_admin_token    => $keystone_admin_token,
    controller_node         => $controller_node_internal,
  }


}

node /compute/ {

  class { 'openstack::compute':
    # compute interfaces
    public_interface      => $compute_pub_interface,
    private_interface     => $compute_pri_interface,
    internal_address      => $compute_node_address,
    libvirt_type          => 'kvm',
    network_manager       => 'nova.network.manager.FlatDHCPManager',
    multi_host            => true,
    # Cinder
    cinder_db_password    => $cinder_db_password,
    # Nova
    nova_db_password      => $nova_db_password,
    nova_user_password    => $nova_user_password,
    # Controller
    db_host               => $controller_node_internal,
    # Neutron
    enable_ovs_agent      => false,
    ovs_enable_tunneling  => false, 
    neutron               => true,
    neutron_user_password => $neutron_user_password,
    neutron_auth_url      => "${controller_node_internal}:35357/v2.0",
    neutron_host          => $controller_node_internal,
    security_group_api    => 'nova',
    # Keystone
    keystone_host         => $controller_node_internal,
    # Rabbit
    rabbit_host           => $controller_node_internal,
    rabbit_password       => $rabbit_password,
    rabbit_user           => $rabbit_user,
    # Glance
    glance_api_servers    => "${controller_node_internal}:9292",
    vncproxy_host         => $controller_node_public,
    vnc_enabled           => true,
    verbose               => $verbose,
    # Cinder Volume
    manage_volumes        => true,
    volume_group          => 'cinder-volumes'
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    admin_tenant         => $admin_tenant,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

}
