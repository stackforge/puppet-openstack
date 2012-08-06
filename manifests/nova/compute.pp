#
# == Class: openstack::compute
#
# Manifest to install/configure nova-compute and nova-volume
#
# === Parameters
#
# See params.pp
#
# === Examples
#
# class { 'openstack::nova::compute':
#   internal_address   => '192.168.2.2',
#   vncproxy_host      => '192.168.1.1',
#   nova_user_password => 'changeme',
# }

class openstack::nova::compute (
  # Required Network
  $internal_address,
  # Required Nova
  $nova_user_password,
  # Required Rabbit
  $rabbit_password,
  # Network
  $public_address                = undef,
  $public_interface              = 'eth0',
  $private_interface             = 'eth1',
  $fixed_range                   = '10.0.0.0/24',
  $network_manager               = 'nova.network.manager.FlatDHCPManager',
  $network_config                = {},
  $multi_host                    = false,
  # DB
  $sql_connection                = false,
  # Nova
  $purge_nova_config              = true,
  # Rabbit
  $rabbit_host                   = false,
  $rabbit_user                   = 'nova',
  # Glance
  $glance_api_servers            = false,
  # Virtualization
  $libvirt_type                  = 'kvm',
  # Volumes
  $nova_volume                   = 'nova-volumes',
  $manage_volumes                = true,
  $iscsi_ip_address              = $internal_address,
  # VNC
  $vnc_enabled                   = true,
  $vncproxy_host                 = undef,
  # General
  $verbose                       = 'False',
  $exported_resources            = true,
  $enabled                       = true
) {

  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ! defined( Resources[nova_config] ) {
    if ($purge_nova_config) {
      resources { 'nova_config':
        purge => true,
      }
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
  if ! defined( Class[nova] ) {
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

  # Install / configure nova-compute
  class { '::nova::compute':
    enabled                       => $enabled,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $internal_address,
    vncproxy_host                 => $vncproxy_host,
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type     => $libvirt_type,
    vncserver_listen => $internal_address,
  }

  # if the compute node should be configured as a multi-host
  # compute installation
  if $multi_host {
    include keystone::python
    nova_config {
      'multi_host':      value => 'True';
      'send_arp_for_ha': value => 'True';
    }
    if ! $public_interface {
      fail('public_interface must be defined for multi host compute nodes')
    }
    $enable_network_service = true
    class { 'nova::api':
      enabled           => true,
      admin_tenant_name => 'services',
      admin_user        => 'nova',
      admin_password    => $nova_user_password,
    }
  } else {
    $enable_network-service = false
    nova_config {
      'multi_host':      value => 'False';
      'send_arp_for_ha': value => 'False';
    }
  }

  # set up configuration for networking
  # NOTE should the if block be removed? -jtopjian
  if $enable_network_service {
    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => false,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => false,
      enabled           => $enable_network_service,
      install_service   => $enable_network_service,
    }
  }

  if $manage_volumes {
    # Install / configure nova-volume
    class { 'nova::volume':
      enabled => $enabled,
    }
    if $enabled {
      class { 'nova::volume::iscsi':
        volume_group     => $nova_volume,
        iscsi_ip_address => $iscsi_ip_address,
      }
    }
  }

}
