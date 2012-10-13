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
  $fixed_range               = '10.0.0.0/24',
  $floating_range            = false,
  $internal_address          = $public_address,
  $admin_address             = $public_address,
  $auto_assign_floating_ip   = false,
  $create_networks           = true,
  $num_networks              = 1,
  $multi_host                = false,
  # Nova
  $nova_db_user              = 'nova',
  $nova_db_dbname            = 'nova',
  # Rabbit
  $rabbit_user               = 'nova',
  # Database
  $db_type                   = 'mysql',
  # Glance
  $glance_api_servers        = undef,
  # VNC
  $vnc_enabled               = true,
  # General
  $keystone_host             = '127.0.0.1',
  $verbose                   = 'False',
  $enabled                   = true,
  $exported_resources        = true
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
  if ($exported_resources) {
    # export all of the things that will be needed by the clients
    @@nova_config { 'rabbit_host': value => $internal_address }
    Nova_config <| title == 'rabbit_host' |>

    @@nova_config { 'sql_connection': value => $nova_db }
    Nova_config <| title == 'sql_connection' |>

    @@nova_config { 'glance_api_servers': value => $real_glance_api_servers }
    Nova_config <| title == 'glance_api_servers' |>

    $sql_connection    = false
    $glance_connection = false
    $rabbit_connection = false
  } else {
    $sql_connection    = $nova_db
    $glance_connection = $real_glance_api_servers
    $rabbit_connection = $internal_address
  }

  # Install / configure rabbitmq
  class { 'nova::rabbitmq':
    userid   => $rabbit_user,
    password => $rabbit_password,
    enabled  => $enabled,
  }

  # Configure Nova
  class { 'nova':
    sql_connection     => $sql_connection,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_connection,
    verbose            => $verbose,
    rabbit_host        => $rabbit_connection,
  }

  # Configure nova-api
  class { 'nova::api':
    enabled           => $enabled,
    admin_password    => $nova_user_password,
    auth_host         => $keystone_host,
  }

  # Configure nova-network
  if $multi_host {
    nova_config { 'multi_host': value => 'True' }
    $enable_network_service = false
  } else {
    if $enabled == true {
      $enable_network_service = true
    } else {
      $enable_network_service = false
    }
  }

  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
  }

  #class { 'nova::network':
  #  private_interface => $private_interface,
  #  public_interface  => $public_interface,
  #  fixed_range       => $fixed_range,
  #  floating_range    => $floating_range,
  #  network_manager   => $network_manager,
  #  config_overrides  => $network_config,
  #  create_networks   => $really_create_networks,
  #  num_networks      => $num_networks,
  #  enabled           => $enable_network_service,
  #  install_service   => $enable_network_service,
  #}

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
