#
# This can be used to build out the simplest openstack controller
#
# === Parameters
#
# See params.pp
#
# === Examples
#
# class { 'openstack::controller':
#   public_address    => '192.168.0.3',
#   public_interface  => 'eth0',
#   private_interface => 'eth1',
#   admin_email       => 'my_email@mw.com',
#   admin_password    => 'my_admin_password',
# }
#
class openstack::controller (
  # Network
  $public_address          = $::openstack::params::public_address,
  $public_interface        = $::openstack::params::public_interface,
  $private_interface       = $::openstack::params::private_interface,
  $internal_address        = $::openstack::params::internal_address,
  $admin_address           = $::openstack::params::admin_address,
  $network_manager         = $::openstack::params::network_manager,
  $fixed_range             = $::openstack::params::fixed_range,
  $floating_range          = $::openstack::params::floating_range,
  $create_networks         = $::openstack::params::create_networks,
  $num_networks            = $::openstack::params::num_networks,
  $multi_host              = $::openstack::params::multi_host,
  $auto_assign_floating_ip = $::openstack::params::auto_assign_floating_ip,
  $network_config          = $::openstack::params::network_config,
  # Database
  $db_type                 = $::openstack::params::db_type,
  $mysql_root_password     = $::openstack::params::mysql_root_password,
  $mysql_account_security  = $::openstack::params::mysql_account_security,
  $mysql_bind_address      = $::openstack::params::mysql_bind_address,
  # Keystone
  $admin_email             = $::openstack::params::admin_email,
  $admin_password          = $::openstack::params::admin_password,
  $keystone_db_user        = $::openstack::params::keystone_db_user,
  $keystone_db_password    = $::openstack::params::keystone_db_password,
  $keystone_db_dbname      = $::openstack::params::keystone_db_dbname,
  $keystone_admin_token    = $::openstack::params::keystone_admin_token,
  # Glance
  $glance_db_user          = $::openstack::params::glance_db_user,
  $glance_db_password      = $::openstack::params::glance_db_password,
  $glance_db_dbname        = $::openstack::params::glance_db_dbname,
  $glance_user_password    = $::openstack::params::glance_user_password,
  $glance_api_servers      = $::openstack::params::glance_api_servers,
  # Nova
  $nova_db_user            = $::openstack::params::nova_db_user,
  $nova_db_password        = $::openstack::params::nova_db_password,
  $nova_user_password      = $::openstack::params::nova_user_password,
  $nova_db_dbname          = $::openstack::params::nova_db_dbname,
  $purge_nova_config       = $::openstack::params::purge_nova_config,
  # Rabbit
  $rabbit_password         = $::openstack::params::rabbit_password,
  $rabbit_user             = $::openstack::params::rabbit_user,
  # Horizon
  $secret_key              = $::openstack::params::secret_key,
  $cache_server_ip         = $::openstack::params::cache_server_ip,
  $cache_server_port       = $::openstack::params::cache_server_port,
  $swift                   = $::openstack::params::swift,
  $quantum                 = $::openstack::params::quantum,
  $horizon_app_links       = $::openstack::params::horizon_app_links,
  # General
  $verbose                 = $::openstack::params::verbose,
  $exported_resources      = $::openstack::params::exported_resources,
  $enabled                 = $::openstack::params::enabled
) inherits openstack::params {

  ####### DATABASE SETUP ######
  if $enabled {
    # set up mysql server
    case $db_type {
      'mysql': {
        class { 'openstack::db::mysql':
          mysql_root_password    => $mysql_root_password,
          mysql_bind_address     => $mysql_bind_address,
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
  }

  ####### KEYSTONE ###########
  if ($enabled) {
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
      internal_address          => $internal_address,
      admin_address             => $admin_address,
    }
  }

  ######## BEGIN GLANCE ##########
  if ($enabled) {
    class { 'openstack::glance':
      verbose                   => $verbose,
      db_type                   => $db_type,
      db_host                   => '127.0.0.1',
      glance_db_user            => $glance_db_user,
      glance_db_dbname          => $glance_db_dbname,
      glance_db_password        => $glance_db_password,
      glance_user_password      => $glance_user_password,
      public_address            => $public_address,
      admin_address             => $admin_address,
      internal_address          => $internal_addrss,
    }
  }

  ######## BEGIN NOVA ###########
  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }

  if $enabled {
    class { 'openstack::nova::controller':
      # Network
      network_manager         => $network_manager,
      network_config          => $network_config,
      private_interface       => $private_interface,
      public_interface        => $public_interface,
      floating_range          => $floating_range,
      fixed_range             => $fixed_range,
      public_address          => $public_address,
      admin_address           => $admin_address,
      internal_address        => $internal_address,
      auto_assign_floating_ip => $auto_assign_floating_ip,
      create_networks         => $create_networks,
      num_networks            => $num_networks,
      multi_host              => $multi_host,
      # Nova
      nova_user_password      => $nova_user_password,
      nova_db_password        => $nova_db_password,
      nova_db_user            => $nova_db_user,
      nova_db_dbname          => $nova_db_dbname,
      # Rabbit
      rabbit_user             => $rabbit_user,
      rabbit_password         => $rabbit_password,
      # Glance
      glance_api_servers      => $glance_api_servers,
      # General
      verbose                 => $verbose,
      enabled                 => $enabled,
      exported_resources      => $exported_resources,
    }
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
