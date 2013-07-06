#
# == Class: openstack::nova::controller
#
# Class to define nova components used in a controller architecture.
# Basically everything but nova-compute and nova-volume
#
# === Parameters
#
# [quantum]
#   Specifies if nova should be configured to use quantum.
#   (optional) Defaults to false (indicating nova-networks should be used)
#
# [quantum_user_password]
#   password that nova uses to authenticate with quantum.
#
# [metadata_shared_secret] Secret used to authenticate between nova and the
#   quantum metadata services.
#   (Optional). Defaults to undef.
#
# === Examples
#
# class { 'openstack::nova::controller':
#   public_address     => '192.168.1.1',
#   db_host            => '127.0.0.1',
#   rabbit_password    => 'changeme',
#   nova_user_password => 'changeme',
#   nova_db_password   => 'changeme',
# }
#

class openstack::nova::controller (
  # Network Required
  $public_address,
  # Database Required
  $db_host,
  # Rabbit Required
  $rabbit_password,
  # Nova Required
  $nova_user_password,
  $nova_db_password,
  # Network
  $network_manager           = 'nova.network.manager.FlatDHCPManager',
  $network_config            = {},
  $floating_range            = false,
  $fixed_range               = '10.0.0.0/24',
  $admin_address             = $public_address,
  $internal_address          = $public_address,
  $auto_assign_floating_ip   = false,
  $create_networks           = true,
  $num_networks              = 1,
  $multi_host                = false,
  $public_interface          = undef,
  $private_interface         = undef,
  # quantum
  $quantum                   = true,
  $quantum_user_password     = false,
  $metadata_shared_secret    = undef,
  # Nova
  $nova_admin_tenant_name    = 'services',
  $nova_admin_user           = 'nova',
  $nova_db_user              = 'nova',
  $nova_db_dbname            = 'nova',
  $enabled_apis              = 'ec2,osapi_compute,metadata',
  # Rabbit
  $rabbit_user               = 'openstack',
  $rabbit_virtual_host       = '/',
  # Database
  $db_type                   = 'mysql',
  # Glance
  $glance_api_servers        = undef,
  # VNC
  $vnc_enabled               = true,
  $vncproxy_host             = undef,
  # Keystone
  $keystone_host             = '127.0.0.1',
  # General
  $verbose                   = false,
  $enabled                   = true
) {

  # Configure the db string
  case $db_type {
    'mysql': {
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}"
    }
    default: {
    }
  }

  if ($glance_api_servers == undef) {
    $real_glance_api_servers = "${public_address}:9292"
  } else {
    $real_glance_api_servers = $glance_api_servers
  }
  if $vncproxy_host {
    $vncproxy_host_real = $vncproxy_host
  } else {
    $vncproxy_host_real = $public_address
  }

  $sql_connection    = $nova_db
  $glance_connection = $real_glance_api_servers
  $rabbit_connection = $internal_address

  # Install / configure rabbitmq
  class { 'nova::rabbitmq':
    userid        => $rabbit_user,
    password      => $rabbit_password,
    enabled       => $enabled,
    virtual_host  => $rabbit_virtual_host,
  }

  # Configure Nova
  class { 'nova':
    sql_connection       => $sql_connection,
    rabbit_userid        => $rabbit_user,
    rabbit_password      => $rabbit_password,
    rabbit_virtual_host  => $rabbit_virtual_host,
    image_service        => 'nova.image.glance.GlanceImageService',
    glance_api_servers   => $glance_connection,
    verbose              => $verbose,
    rabbit_host          => $rabbit_connection,
  }

  # Configure nova-api
  class { 'nova::api':
    enabled                              => $enabled,
    admin_tenant_name                    => $nova_admin_tenant_name,
    admin_user                           => $nova_admin_user,
    admin_password                       => $nova_user_password,
    enabled_apis                         => $enabled_apis,
    auth_host                            => $keystone_host,
    quantum_metadata_proxy_shared_secret => $metadata_shared_secret,
  }


  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
  }

  if $quantum == false {
    # Configure nova-network
    if $multi_host {
      nova_config { 'DEFAULT/multi_host': value => true }
      $enable_network_service = false
    } else {
      if $enabled {
        $enable_network_service = true
      } else {
        $enable_network_service = false
      }
    }

    if ! $private_interface  {
      fail('private interface must be set when nova networking is used')
    }
    if ! $public_interface  {
      fail('public interface must be set when nova networking is used')
    }

    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => $floating_range,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => $really_create_networks,
      num_networks      => $num_networks,
      enabled           => $enable_network_service,
      install_service   => $enable_network_service,
    }
  } else {
    # Configure Nova for Quantum networking

    if ! $quantum_user_password {
      fail('quantum_user_password must be specified when quantum is configured')
    }

    class { 'nova::network::quantum':
      quantum_admin_password    => $quantum_user_password,
      quantum_auth_strategy     => 'keystone',
      quantum_url               => "http://${keystone_host}:9696",
      quantum_admin_tenant_name => 'services',
      quantum_admin_username    => 'quantum',
      quantum_admin_auth_url    => "http://${keystone_host}:35357/v2.0",
    }
  }

  if $auto_assign_floating_ip {
    nova_config { 'DEFAULT/auto_assign_floating_ip': value => true }
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::cert',
    'nova::consoleauth',
    'nova::conductor'
  ]:
    enabled => $enabled,
  }

  if $vnc_enabled {
    class { 'nova::vncproxy':
      host    => $vncproxy_host_real,
      enabled => $enabled,
    }
  }

}
