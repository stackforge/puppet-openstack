#
# == Class: openstack::compute
#
# This class is intended to serve as
# a way of deploying compute nodes.
#
# This currently makes the following assumptions:
#   - libvirt is used to manage the hypervisors
#   - flatdhcp networking is used
#   - glance is used as the backend for the image service
#
# === Parameters
#
# See params.pp
#
# === Examples
#
# class { 'openstack::compute': 
#   libvirt_type => 'kvm',
# }
#

class openstack::compute (
  # Network
  $public_address      = $::openstack::params::public_address,
  $public_interface    = $::openstack::params::public_interface,
  $private_interface   = $::openstack::params::private_interface,
  $internal_address    = $::openstack::params::internal_address,
  $fixed_range         = $::openstack::params::fixed_range,
  $network_manager     = $::openstack::params::network_manager,
  $multi_host          = $::openstack::params::multi_host,
  $network_config      = $::openstack::params::network_config,
  # DB
  $sql_connection      = $::openstack::params::sql_connection,
  # Nova
  $nova_user_password  = $::openstack::params::nova_user_password,
  $purge_nova_config   = $::openstack::params::purge_nova_config,
  # Rabbit
  $rabbit_host         = $::openstack::params::rabbit_host,
  $rabbit_password     = $::openstack::params::rabbit_password,
  $rabbit_user         = $::openstack::params::rabbit_user,
  # Glance
  $glance_api_servers  = false,
  # Virtualization
  $libvirt_type        = $::openstack::params::libvirt_type,
  # VNC
  $vncproxy_host       = $::openstack::params::vncproxy_host,
  $vnc_enabled         = $::openstack::params::vnc_enabled,
  $vncserver_proxyclient_address = $::openstack::params::vncserver_proxyclient_address,
  # Volumes
  $manage_volumes      = $::openstack::params::manage_volumes,
  $nova_volume         = $::openstack::params::nova_volume,
  # General
  $verbose             = $::openstack::params::verbose,
  $exported_resources  = $::openstack::params::exported_resources,
  $enabled             = $::openstack::params::enabled
) inherits openstack::params {

  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }

  if $exported_resources {
    Nova_config <<||>>
    $final_sql_connection = false
    $glance_connection = false
    $rabbit_connection = false
  } else {
    $final_sql_connection = $sql_connection
    $glance_connection = $glance_api_servers
    $rabbit_connection = $rabbit_host
  }

  # Configure Nova
  if $enabled {
    class { 'nova':
      sql_connection     => $final_sql_connection,
      rabbit_userid      => $rabbit_user,
      rabbit_password    => $rabbit_password,
      image_service      => 'nova.image.glance.GlanceImageService',
      glance_api_servers => $glance_connection,
      verbose            => $verbose,
      rabbit_host        => $rabbit_connection,
    }
  }

  if $enabled {
    class { 'openstack::nova::compute':
      # Network
      public_address                => $public_address,
      private_interface             => $private_interface,
      public_interface              => $public_interface,
      fixed_range                   => $fixed_range,
      network_manager               => $network_manager,
      network_config                => $network_config,
      multi_host                    => $multi_host,
      # Virtualization
      libvirt_type                  => $libvirt_type,
      # Volumes
      nova_volume                   => $nova_volume,
      manage_volumes                => $manage_volumes,
      iscsi_ip_address              => $iscsi_ip_address,
      # VNC
      vnc_enabled                   => $vnc_enabled,
      vncserver_listen              => $vnc_server_listen,
      vncserver_proxyclient_address => $vncserver_proxyclient_address,
      vncproxy_host                 => $vncproxy_host,
      # Nova 
      nova_user_password            => $nova_user_password,
      # General
      verbose                       => $verbose,
      exported_resources            => $exported_resources,
      enabled                       => $enabled,
    }
  }

}
