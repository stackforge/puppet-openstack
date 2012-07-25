#
# == Class: openstack::all
#
# Class that performs a basic openstack all in one installation.
#
# === Parameters
#
# See params.pp
#
# === Examples
#
#  class { 'openstack::all':
#    public_address       => '192.168.1.1',
#    mysql_root_password  => 'changeme',
#    rabbit_password      => 'changeme',
#    keystone_db_password => 'changeme',
#    keystone_admin_token => '12345',
#    admin_email          => 'my_email@mw.com',
#    admin_password       => 'my_admin_password',
#    nova_db_password     => 'changeme',
#    nova_user_password   => 'changeme',
#    glance_db_password   => 'changeme',
#    glance_user_password => 'changeme',
#    secret_key           => 'dummy_secret_key',
#  }
#
# === Authors
#
# Dan Bode <bodepd@gmail.com>
#
#
class openstack::all (
  # Network
  $public_interface        = 'eth0',
  $private_interface       = 'eth1',
  $fixed_range             = '10.0.0.0/24',
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $network_config          = {},
  $auto_assign_floating_ip = false,
  $floating_range          = false,
  $create_networks         = true,
  $num_networks            = 1,
  # MySQL
  $db_type                 = 'mysql',
  $mysql_account_security  = true,
  $allowed_hosts           = ['127.0.0.%'],
  # Rabbit
  $rabbit_user             = 'nova',
  # Keystone
  $keystone_db_user        = 'keystone',
  $keystone_db_dbname      = 'keystone',
  # Nova
  $nova_db_user            = 'nova',
  $nova_db_dbname          = 'nova',
  $purge_nova_config       = true,
  # Glance
  $glance_db_user          = 'glance',
  $glance_db_dbname        = 'glance',
  # Horizon
  $cache_server_ip         = '127.0.0.1',
  $cache_server_port       = '11211',
  $swift                   = false,
  $quantum                 = false,
  $horizon_app_links       = undef,
  # Virtaulization
  $libvirt_type            = 'kvm',
  # Volume
  $nova_volume             = 'nova-volumes',
  # VNC
  $vnc_enabled             = true,
  # General
  $enabled                 = true,
  $verbose                 = false,
  # Network Required
  $public_address,
  # MySQL Required
  $mysql_root_password,
  # Rabbit Required
  $rabbit_password,
  # Keystone Required
  $keystone_db_password,
  $keystone_admin_token,
  $admin_email,
  $admin_password,
  # Nova Required
  $nova_db_password,
  $nova_user_password,
  # Glance Required
  $glance_db_password,
  $glance_user_password,
  # Horizon Required
  $secret_key,
) inherits openstack::params {

  # set up mysql server
  case $db_type {
    'mysql': {
      class { 'openstack::db::mysql':
        mysql_root_password    => $mysql_root_password,
        mysql_bind_address     => '127.0.0.1',
        mysql_account_security => $mysql_account_security,
        keystone_db_user       => $keystone_db_user,
        keystone_db_password   => $keystone_db_password,
        keystone_db_dbname     => $keystone_db_dbname,
        glance_db_user         => $glance_db_user,
        glance_db_password     => $glance_db_password,
        glance_db_dbname       => $glance_db_dbname,
        nova_db_user           => $nova_db_user,
        nova_db_password       => $nova_db_password,
        nova_db_dbname         => $nova_db_dbname,
        allowed_hosts          => $allowed_hosts,
      }
    }
  }
  ####### KEYSTONE ###########
  class { 'openstack::keystone':
    verbose                   => $verbose,
    db_type                   => $db_type,
    db_host                   => '127.0.0.1',
    keystone_db_password      => $keystone_db_password,
    keystone_db_dbname        => $keystone_db_dbname,
    keystone_db_user          => $keystone_db_user,
    keystone_admin_token      => $keystone_admin_token,
    admin_email               => $admin_email,
    admin_password            => $admin_password,
    public_address            => $public_address,
    internal_address          => '127.0.0.1',
    admin_address             => '127.0.0.1',
  }

  ######## GLANCE ##########
  class { 'openstack::glance':
    verbose                   => $verbose,
    db_type                   => $db_type,
    db_host                   => '127.0.0.1',
    glance_db_user            => $glance_db_user,
    glance_db_dbname          => $glance_db_dbname,
    glance_db_password        => $glance_db_password,
    glance_user_password      => $glance_user_password,
    public_address            => $public_address,
    admin_address             => '127.0.0.1',
    internal_address          => '127.0.0.1',
  }

  ######## NOVA ###########

  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }

  class { 'openstack::nova::controller':
    # Network
    network_manager         => $network_manager,
    network_config          => $network_config,
    private_interface       => $private_interface,
    public_interface        => $public_interface,
    floating_range          => $floating_range,
    fixed_range             => $fixed_range,
    public_address          => $public_address,
    admin_address           => '127.0.0.1',
    internal_address        => '127.0.0.1',
    auto_assign_floating_ip => $auto_assign_floating_ip,
    create_networks         => $create_networks,
    num_networks            => $num_networks,
    multi_host              => false,
    # Database
    db_host                 => '127.0.0.1',
    # Nova
    nova_user_password      => $nova_user_password,
    nova_db_password        => $nova_db_password,
    nova_db_user            => $nova_db_user,
    nova_db_dbname          => $nova_db_dbname,
    # Rabbit
    rabbit_user             => $rabbit_user,
    rabbit_password         => $rabbit_password,
    # Glance
    glance_api_servers      => '127.0.0.1:9292',
    # VNC
    vnc_enabled             => $vnc_enabled,
    # General
    verbose                 => $verbose,
    enabled                 => $enabled,
    exported_resources      => false,
  }

  class { 'openstack::nova::compute':
    # Network
    public_address                => $public_address,
    private_interface             => $private_interface,
    public_interface              => $public_interface,
    fixed_range                   => $fixed_range,
    network_manager               => $network_manager,
    network_config                => $network_config,
    multi_host                    => false,
    internal_address              => '127.0.0.1',
    # Virtualization
    libvirt_type                  => $libvirt_type,
    # Volumes
    nova_volume                   => $nova_volume,
    manage_volumes                => true,
    iscsi_ip_address              => '127.0.0.1',
    # VNC
    vnc_enabled                   => $vnc_enabled,
    vncserver_listen              => $vnc_server_listen,
    vncserver_proxyclient_address => '127.0.0.1',
    vncproxy_host                 => '127.0.0.1',
    # Nova
    nova_user_password            => $nova_user_password,
    # General
    verbose                       => $verbose,
    exported_resources            => false,
    enabled                       => $enabled,
  }

  ######## Horizon ########
  class { 'openstack::horizon':
    secret_key        => $secret_key,
    cache_server_ip   => $cache_server_ip,
    cache_server_port => $cache_server_port,
    swift             => $swift,
    quantum           => $quantum,
    horizon_app_links => $horizon_app_links,
  }

  ######## auth file ########
  class { 'openstack::auth_file': }

}
