#
# == Class: openstack::nova::controller
#
# Class to define nova components used in a controller architecture.
# Basically everything but nova-compute and nova-volume
#
# === Parameters
#
# See params.pp
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
  $quantum                   = false,
  $quantum_db_dbname         = 'quantum',
  $quantum_db_user           = 'quantum',
  $quantum_db_password       = 'quantum_pass',
  $quantum_user_password     = 'quantum_pass',
  # Nova
  $nova_db_user              = 'nova',
  $nova_db_dbname            = 'nova',
  # Rabbit
  $rabbit_user               = 'nova',
  $rabbit_virtual_host       = '/',
  # Database
  $db_type                   = 'mysql',
  # Glance
  $glance_api_servers        = undef,
  # VNC
  $vnc_enabled               = true,
  # General
  $keystone_host             = '127.0.0.1',
  $verbose                   = 'False',
  $enabled                   = true
) {

  # Configure the db string
  case $db_type {
    'mysql': {
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}"
    }
  }

  if ($glance_api_servers == undef) {
    $real_glance_api_servers = "${public_address}:9292"
  } else {
    $real_glance_api_servers = $glance_api_servers
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
    enabled           => $enabled,
    admin_password    => $nova_user_password,
    auth_host         => $keystone_host,
  }


  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
  }

  if $quantum == false {
    # Configure nova-network
    if $multi_host {
      nova_config { 'multi_host': value => 'True' }
      $enable_network_service = false
    } else {
      if $enabled {
        $enable_network_service = true
      } else {
        $enable_network_service = false
      }
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
    # Set up Quantum
    $quantum_sql_connection = "mysql://${quantum_db_user}:${quantum_db_password}@${db_host}/${quantum_db_dbname}?charset=utf8"
    class { 'quantum':
      rabbit_user     => $rabbit_user,
      rabbit_password => $rabbit_password,
      #sql_connection  => $quantum_sql_connection,
      verbose         => $verbose,
      debug           => $verbose,
    }

    class { 'quantum::server':
      auth_password => $quantum_user_password,
    }

    class { 'quantum::plugins::ovs':
      sql_connection      => $quantum_sql_connection,
      tenant_network_type => 'gre',
      enable_tunneling    => true,
    }

    class { 'quantum::agents::ovs':
      bridge_uplinks   => ["br-virtual:${private_interface}"],
      enable_tunneling => true,
      local_ip         => $internal_address,
    }

    class { 'quantum::agents::dhcp':
      use_namespaces => False,
    }


#    class { 'quantum::agents::dhcp':
#      use_namespaces => False,
#    }
#
#
#    class { 'quantum::agents::l3':
#      auth_password => $quantum_user_password,
#    }

    class { 'nova::network::quantum':
    #$fixed_range,
      quantum_admin_password    => $quantum_user_password,
    #$use_dhcp                  = 'True',
    #$public_interface          = undef,
      quantum_connection_host   => 'localhost',
      quantum_auth_strategy     => 'keystone',
      quantum_url               => "http://${keystone_host}:9696",
      quantum_admin_tenant_name => 'services',
      #quantum_admin_username    => 'quantum',
      quantum_admin_auth_url    => "http://${keystone_host}:35357/v2.0",
    }
  }

  if $auto_assign_floating_ip {
    nova_config { 'auto_assign_floating_ip': value => 'True' }
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::cert',
    'nova::consoleauth'
  ]:
    enabled => $enabled,
  }

  if $vnc_enabled {
    class { 'nova::vncproxy':
      host    => $public_address,
      enabled => $enabled,
    }
  }

}
