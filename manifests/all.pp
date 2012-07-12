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
#    public_address       => '192.168.0.3',
#    public_interface     => 'eth0',
#    private_interface    => 'eth1',
#    admin_email          => 'my_email@mw.com',
#    admin_password       => 'my_admin_password',
#    libvirt_type         => 'kvm',
#  }
#
# === Authors
#
# Dan Bode <bodepd@gmail.com>
#
#
class openstack::all (
  # Network
  $public_address          = $::openstack::params::public_address,
  $public_interface        = $::openstack::params::public_interface,
  $private_interface       = $::openstack::params::private_interface,
  $fixed_range             = $::openstack::params::fixed_range,
  $network_manager         = $::openstack::params::network_manager,
  $network_config          = $::openstack::params::network_config,
  $auto_assign_floating_ip = $::openstack::params::auto_assign_floating_ip,
  $floating_range          = $::openstack::params::floating_range,
  $create_networks         = $::openstack::params::create_networks,
  $num_networks            = $::openstack::params::num_networks,
  # MySQL
  $db_type                 = $::openstack::params::db_type,
  $mysql_root_password     = $::openstack::params::mysql_root_password,
  $mysql_account_security  = $::openstack::params::mysql_account_security,
  # Rabbit
  $rabbit_password         = $::openstack::params::rabbit_password,
  $rabbit_user             = $::openstack::params::rabbit_user,
  # Keystone
  $admin_email             = $::openstack::params::admin_email,
  $admin_password          = $::openstack::params::admin_password,
  $keystone_db_user        = $::openstack::params::keystone_db_user,
  $keystone_db_password    = $::openstack::params::keystone_db_password,
  $keystone_db_dbname      = $::openstack::params::keystone_db_dbname,
  $keystone_admin_token    = $::openstack::params::keystone_admin_token,
  # Nova
  $nova_db_user            = $::openstack::params::nova_db_user,
  $nova_db_password        = $::openstack::params::nova_db_password,
  $nova_user_password      = $::openstack::params::nova_user_password,
  $nova_db_dbname          = $::openstack::params::nova_db_dbname,
  $purge_nova_config       = $::openstack::params::purge_nova_config,
  # Glance
  $glance_db_user          = $::openstack::params::glance_db_user,
  $glance_db_password      = $::openstack::params::glance_db_password,
  $glance_db_dbname        = $::openstack::params::glance_db_dbname,
  $glance_user_password    = $::openstack::params::glance_user_password,
  # Horizon
  $secret_key              = $::openstack::params::secret_key,
  $cache_server_ip         = $::openstack::params::cache_server_ip,
  $cache_server_port       = $::openstack::params::cache_server_port,
  $swift                   = $::openstack::params::swift,
  $quantum                 = $::openstack::params::quantum,
  $horizon_app_links       = $::openstack::params::horizon_app_links,
  # Virtaulization
  $libvirt_type            = $::openstack::params::libvirt_type,
  # Volume
  $nova_volume             = $::openstack::params::nova_volume,
  # VNC
  $vnc_enabled             = $::openstack::params::vnc_enabled,
  # General
  $enabled                 = $::openstack::params::enabled,
  $verbose                 = $::openstack::params::verbose
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
