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

class openstack::nova::controller (
  # Network
  $network_manager           = $::openstack::params::network_manager,
  $network_config            = $::openstack::params::network_config,
  $private_interface         = $::openstack::params::private_interface,
  $public_interface          = $::openstack::params::public_interface,
  $floating_range            = $::openstack::params::floating_range,
  $fixed_range               = $::openstack::params::fixed_range,
  $public_address            = $::openstack::params::public_address,
  $admin_address             = $::openstack::params::admin_address,
  $internal_address          = $::openstack::params::internal_address,
  $auto_assign_floating_ip   = $::openstack::params::auto_assign_floating_ip,
  $create_networks           = $::openstack::params::create_networks,
  $num_networks              = $::openstack::params::num_networks,
  $multi_host                = $::openstack::params::multi_host,
  # Nova
  $nova_user_password        = $::openstack::params::nova_user_password,
  $nova_db_user              = $::openstack::params::nova_db_user,
  $nova_db_password          = $::openstack::params::nova_db_password,
  $nova_db_dbname            = $::openstack::params::nova_db_dbname,
  # Rabbit
  $rabbit_user               = $::openstack::params::rabbit_user,
  $rabbit_password           = $::openstack::params::rabbit_password,
  # Database
  $db_type                   = $::openstack::params::db_type,
  $db_host                   = $::openstack::params::db_host,
  # Glance
  $glance_api_servers        = $::openstack::params::glance_api_servers,
  # VNC
  $vnc_enabled               = $::openstack::params::vnc_enabled,
  # General
  $verbose                   = $::openstack::params::verbose,
  $enabled                   = $::openstack::params::enabled,
  $exported_resources        = $::openstack::params::exported_resources
) inherits openstack::params {

  # Configure the db string
  case $db_type {
    'mysql': {
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}"
    }
  }

  # Might need fixed
  # $glance_api_servers = "${internal_address}:9292"
 
  if ($export_resources) {
    # export all of the things that will be needed by the clients
    @@nova_config { 'rabbit_host': value => $internal_address }
    Nova_config <| title == 'rabbit_host' |>

    @@nova_config { 'sql_connection': value => $nova_db }
    Nova_config <| title == 'sql_connection' |>

    @@nova_config { 'glance_api_servers': value => $glance_api_servers }
    Nova_config <| title == 'glance_api_servers' |>

    @@nova_config { 'novncproxy_base_url': value => "http://${public_address}:6080/vnc_auto.html" }

    $sql_connection    = false
    $glance_connection = false
    $rabbit_connection = false
  } else {
    $sql_connection    = $nova_db
    $glance_connection = $glance_api_servers
    $rabbit_connection = $internal_address
  }


  # Install / configure rabbitmq
  class { 'nova::rabbitmq':
    userid   => $rabbit_user,
    password => $rabbit_password,
  }

  # Configure Nova to use Keystone
  class { 'nova::keystone::auth':
    password         => $nova_user_password,
    public_address   => $public_address,
    admin_address    => $admin_address,
    internal_address => $internal_address,
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
    enabled        => $enabled,
    admin_password => $nova_user_password,
  }

  # Configure nova-network
  if $multi_host {
    nova_config { 'multi_host': value => 'True' }
    $enable_network_service = false
  } else {
    if $enabled == true {
      $enable_network_service = true
    } else {
      $enable_network-service = false
    }
  }

  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
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

  if $auto_assign_floating_ip {
    nova_config { 'auto_assign_floating_ip': value => 'True' }
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::volume',
    'nova::cert',
    'nova::consoleauth'
  ]:
    enabled => true
  }

  if $vnc_enabled {
    class { 'nova::vncproxy':
      enabled => true,
      host    => $public_address,
    }
  }

}
