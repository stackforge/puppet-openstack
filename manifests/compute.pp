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
#   internal_address   => '192.168.1.12',
#   vncproxy_host      => '192.168.1.1',
#   nova_user_password => 'changeme',
#   rabbit_password    => 'changeme',
# }
#

class openstack::compute (
  # Network
  $public_address      = undef,
  $public_interface    = 'eth0',
  $private_interface   = 'eth1',
  $fixed_range         = '10.0.0.0/24',
  $network_manager     = 'nova.network.manager.FlatDHCPManager',
  $multi_host          = false,
  $network_config      = {},
  # DB
  $sql_connection      = false,
  # Nova
  $purge_nova_config   = true,
  # Rabbit
  $rabbit_host         = false,
  $rabbit_user         = 'nova',
  # Glance
  $glance_api_servers  = false,
  # Virtualization
  $libvirt_type        = 'kvm',
  # VNC
  $vnc_enabled         = true,
  $vncserver_listen    = undef,
  $vncproxy_host       = undef,
  $vncserver_proxyclient_address = undef,
  # Volumes
  $manage_volumes      = true,
  $nova_volume         = 'nova-volumes',
  # General
  $verbose             = false,
  $exported_resources  = true,
  $enabled             = true,
  # Required Network
  $internal_address,
  # Required Nova
  $nova_user_password,
  # Required Rabbit
  $rabbit_password
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

  # Configure VNC variables
  if ($vnc_enabled == true) {
    if ($vncserver_listen == undef) {
      $real_vncserver_listen = $internal_address
    } else {
      $real_vncserver_listen = $vncserver_listen
    }

    if ($vncserver_proxyclient_address == undef) {
      $real_vncserver_proxyclient_address = $internal_address
    } else {
      $real_vncserver_proxyclient_address = $vncserver_proxyclient_address
    }

    if ($vncproxy_host == undef) {
      if ($multi_host == true and $public_address != undef) {
        $real_vncproxy_host = $public_address
      } else {
        fail('vncproxy_host must be set.')
      }
    } else {
      # This should be the public IP of the cloud controller...
      $real_vncproxy_host = $vncproxy_host
    }
  } else {
    $real_vncserver_listen = undef
    $real_vncserver_proxyclient_address = undef
    $real_vncproxy_host = undef
  }

  if $enabled {
    class { 'openstack::nova::compute':
      # Network
      public_address                => $public_address,
      internal_address              => $internal_address,
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
      vncserver_listen              => $real_vncserver_listen,
      vncserver_proxyclient_address => $real_vncserver_proxyclient_address,
      vncproxy_host                 => $real_vncproxy_host,
      # Nova 
      nova_user_password            => $nova_user_password,
      # General
      verbose                       => $verbose,
      exported_resources            => $exported_resources,
      enabled                       => $enabled,
    }
  }

}
