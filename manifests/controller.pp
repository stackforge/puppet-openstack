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
#   public_address       => '192.168.0.3',
#   mysql_root_password  => 'changeme',
#   allowed_hosts        => ['127.0.0.%', '192.168.1.%'],
#   admin_email          => 'my_email@mw.com',
#   admin_password       => 'my_admin_password',
#   keystone_db_password => 'changeme',
#   keystone_admin_token => '12345',
#   glance_db_password   => 'changeme',
#   glance_user_password => 'changeme',
#   nova_db_password     => 'changeme',
#   nova_user_password   => 'changeme',
#   secret_key           => 'dummy_secret_key',
# }
#
class openstack::controller (
  # Network
  $public_interface        = 'eth0',
  $private_interface       = 'eth1',
  $internal_address        = undef,
  $admin_address           = undef,
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $fixed_range             = '10.0.0.0/24',
  $floating_range          = false,
  $create_networks         = true,
  $num_networks            = 1,
  $multi_host              = false,
  $auto_assign_floating_ip = false,
  $network_config          = {},
  # Database
  $db_type                 = 'mysql',
  $mysql_account_security  = true,
  $mysql_bind_address      = '0.0.0.0',
  $allowed_hosts           = ['127.0.0.%'],
  # Keystone
  $keystone_db_user        = 'keystone',
  $keystone_db_dbname      = 'keystone',
  # Glance
  $glance_db_user          = 'glance',
  $glance_db_dbname        = 'glance',
  $glance_api_servers      = undef,
  # Nova
  $nova_db_user            = 'nova',
  $nova_db_dbname          = 'nova',
  $purge_nova_config       = true,
  # Rabbit
  $rabbit_password,
  $rabbit_user             = 'nova',
  # Horizon
  $cache_server_ip         = '127.0.0.1',
  $cache_server_port       = '11211',
  $swift                   = false,
  $quantum                 = false, 
  $horizon_app_links       = undef,
  # General
  $verbose                 = false,
  $exported_resources      = true,
  $enabled                 = true,
  # Required Network
  $public_address,
  # Required Database
  $mysql_root_password,
  # Required Keystone
  $admin_email,
  $admin_password,
  $keystone_db_password,
  $keystone_admin_token,
  # Required Glance
  $glance_db_password,
  $glance_user_password,
  # Required Nova
  $nova_db_password,
  $nova_user_password,
  # Required Horizon
  $secret_key
) inherits openstack::params {


  ## NOTE Class['glance::db::mysql'] -> Class['glance::registry']
  ## this dependency needs to exist (I forgot exactly why?)
  # the db migration needs to happen after the dbs are created

  # Configure admin_address and internal address if needed.
  if (admin_address == undef) {
    $real_admin_address = $public_address
  } else {
    $real_admin_address = $admin_address
  }

  if (internal_address == undef) {
    $real_internal_address = $public_address
  } else {
    $real_internal_address = $internal_address
  }

  ####### DATABASE SETUP ######
  if $enabled {
    # set up mysql server
    case $db_type {
      'mysql': {
        class { 'openstack::db::mysql':
          mysql_root_password    => $mysql_root_password,
          mysql_bind_address     => $mysql_bind_address,
          mysql_account_security => $mysql_account_security,
          allowed_hosts          => $allowed_hosts,
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
      # Database
      db_host                 => '127.0.0.1',
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
