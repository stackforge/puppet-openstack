# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#
# For complete installation example, please refer to:
#   http://edin.no-ip.com/blog/hswong3i/openstack-folsom-deploy-puppet-ubuntu-12-04-howto

Exec {
  logoutput => true,
}

####### Start Shared Variables ##################

# This section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments.

# Assumes that eth0 is the public interface.
$public_interface        = 'eth0'
# Assumes that eth1 is the interface that will be used for the vm network
# this configuration assumes this interface is active but does not have an
# ip address allocated to it.
$private_interface       = 'eth1'
$fixed_network_range     = '10.1.0.0/16'
$floating_network_range  = '172.24.1.0/24'

# Database settings.
$mysql_root_password     = 'mysql_root_password'
$keystone_db_password    = 'keystone_db_password'
$glance_db_password      = 'glance_db_password'
$nova_db_password        = 'nova_db_password'
$cinder_db_password      = 'cinder_db_password'
$quantum_db_password     = 'quantum_db_password'

# Rabbit settings.
$rabbit_password         = 'rabbit_password'
$rabbit_user             = 'nova'

# Keystone settings.
$admin_email             = 'root@localhost'
$admin_password          = 'keystone_admin'
$keystone_admin_token    = 'keystone_admin_token'
$glance_user_password    = 'glance_user_password'
$nova_user_password      = 'nova_user_password'
$cinder_user_password    = 'cinder_user_password'
$quantum_user_password   = 'quantum_user_password'

# Misc settings.
$libvirt_type            = 'kvm'
$network_type            = 'nova'
$secret_key              = 'secret_key'
$verbose                 = true

#### End Shared Variables #################

#### Start Multi-node Specific Parameters #################

$controller_node_address  = '172.24.0.11'
$controller_node_public   = $controller_node_address
$controller_node_internal = $controller_node_address

#### End Multi-node Specific Parameters #################

if $network_type == 'nova' {
  $use_quantum = false
  $multi_host = true
} else {
  $use_quantum = true
}

# All nodes whose certname matches openstack_all should be
# deployed as all-in-one openstack installations.
node /openstack_all/ {

  keystone_config {
    'DEFAULT/log_config': ensure => absent,
  }

  # Deploy a script that can be used to test nova.
  class { 'openstack::test_file':
    quantum    => $use_quantum,
    image_type => 'ubuntu',
  }

  # Create a test volume on a loopback device for testing.
#  class { 'cinder::setup_test_volume': } -> Service<||>

  include 'apache'

  class { 'openstack::all':
    public_address          => $ipaddress_eth0,
    internal_address        => $ipaddress_eth0,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    mysql_root_password     => $mysql_root_password,
    secret_key              => $secret_key,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    quantum_user_password   => $quantum_user_password,
    quantum_db_password     => $quantum_db_password,
    cinder_user_password    => $cinder_user_password,
    cinder_db_password      => $cinder_db_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    libvirt_type            => $libvirt_type,
    floating_range          => $floating_network_range,
    fixed_range             => $fixed_network_range,
    verbose                 => $verbose,
    quantum                 => $use_quantum,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => '127.0.0.1',
  }

  # TODO Not sure why this is required.
  # This has a bug, and is constantly added to the file.
  Package['libvirt'] ->
  file_line { 'quemu_hack':
    line => 'cgroup_device_acl = [
      "/dev/null", "/dev/full", "/dev/zero",
      "/dev/random", "/dev/urandom",
      "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
      "/dev/rtc", "/dev/hpet", "/dev/net/tun",]',
    path => '/etc/libvirt/qemu.conf',
    ensure => present,
  } ~> Service['libvirt']
}

# All nodes whose certname matches openstack_controller should be
# deployed as openstack controller installations.
node /openstack_controller/ {

  keystone_config {
    'DEFAULT/log_config': ensure => absent,
  }

  package { 'python-cliff':
    ensure => present,
  }

  # Deploy a script that can be used to test nova.
  class { 'openstack::test_file':
    quantum    => $use_quantum,
    image_type => 'ubuntu',
  }

  if $::osfamily == 'Debian' {
    include 'apache'
  } else {
    package { 'httpd':
      ensure => present
    }~>
    service { 'httpd':
      ensure => running,
      enable => true
    }
  }

  class { 'openstack::controller':
    # Required Network.
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    # Required Database.
    mysql_root_password     => $mysql_root_password,
    # Required Keystone.
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    # Required Glance.
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    # Required Nova.
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    # Cinder.
    cinder_db_password      => $cinder_db_password,
    cinder_user_password    => $cinder_user_password,
    cinder                  => true,
    # Quantum.
    quantum                 => $use_quantum,
    quantum_db_password     => $quantum_db_password,
    quantum_user_password   => $quantum_user_password,
    # Horizon.
    secret_key              => $secret_key,
    # Need to sort out networking...
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    fixed_range             => $fixed_network_range,
    floating_range          => $floating_network_range,
    create_networks         => true,
    multi_host              => $multi_host,
    db_host                 => '127.0.0.1',
    db_type                 => 'mysql',
    mysql_account_security  => true,
    # TODO - This should not allow all...
    allowed_hosts           => '%',
    # Glance.
    glance_api_servers      => '127.0.0.1:9292',
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    # Horizon.
    cache_server_ip         => '127.0.0.1',
    cache_server_port       => '11211',
    swift                   => false,
    horizon_app_links       => undef,
    # General.
    verbose                 => $verbose,
    purge_nova_config       => true,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }
}

# All nodes whose certname matches openstack_compute should be
# deployed as openstack compute installations.
node /openstack_compute/ {

  # Create a test volume on a loopback device for testing.
#  class { 'cinder::setup_test_volume': } -> Service<||>

  class { 'openstack::compute':
    public_interface       => $public_interface,
    private_interface      => $private_interface,
    internal_address       => $ipaddress_eth0,
    libvirt_type           => $libvirt_type,
    sql_connection         => "mysql://nova:${nova_db_password}@${controller_node_internal}/nova",
    cinder_sql_connection  => "mysql://cinder:${cinder_db_password}@${controller_node_internal}/cinder",
    quantum_sql_connection => "mysql://quantum:${quantum_db_password}@${controller_node_internal}/quantum?charset=utf8",
    multi_host             => $multi_host,
    fixed_range            => $fixed_network_range,
    network_manager        => 'nova.network.manager.FlatDHCPManager',
    nova_user_password     => $nova_user_password,
    quantum                => $use_quantum,
    quantum_host           => $controller_node_internal,
    quantum_user_password  => $quantum_user_password,
    rabbit_password        => $rabbit_password,
    glance_api_servers     => "${controller_node_internal}:9292",
    rabbit_host            => $controller_node_internal,
    rabbit_user            => $rabbit_user,
    keystone_host          => $controller_node_internal,
    vncproxy_host          => $controller_node_public,
    vnc_enabled            => true,
    verbose                => $verbose,
    purge_nova_config      => true,
  }

  # TODO Not sure why this is required.
  # This has a bug, and is constantly added to the file
  if $libvirt_type == 'qemu' {
    Package['libvirt'] ->
    file_line { 'quemu_hack':
      line => 'cgroup_device_acl = [
        "/dev/null", "/dev/full", "/dev/zero",
        "/dev/random", "/dev/urandom",
        "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
        "/dev/rtc", "/dev/hpet", "/dev/net/tun",]',
      path => '/etc/libvirt/qemu.conf',
      ensure => present,
    } ~> Service['libvirt']
  }
}
