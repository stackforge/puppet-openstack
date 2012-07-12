#
# == Class: openstack::nova::compute
#
# Manifest to install/configure nova-compute and nova-volume
#
# === Parameters
#
# See params.pp
#

class openstack::nova::compute (
  # Network
  $public_address                = $::openstack::params::public_address,
  $private_interface             = $::openstack::params::private_interface,
  $public_interface              = $::openstack::params::public_interface,
  $fixed_range                   = $::openstack::params::fixed_range,
  $network_manager               = $::openstack::params::network_manager,
  $network_config                = $::openstack::params::network_config,
  $multi_host                    = $::openstack::params::multi_host,
  # Virtualization
  $libvirt_type                  = $::openstack::params::libvirt_type,
  # Volumes
  $nova_volume                   = $::openstack::params::nova_volume,
  $manage_volumes                = $::openstack::params::manage_volume,
  $iscsi_ip_address              = $::openstack::params::iscsi_ip_address,
  # VNC
  $vnc_enabled                   = $::openstack::params::vnc_enabled,
  $vncserver_listen              = $::openstack::params::vncserver_listen,
  $vncserver_proxyclient_address = $::openstack::params::vncserver_proxyclient_address,
  $vncproxy_host                 = $::openstack::params::vncproxy_host,
  # Nova
  $nova_user_password            = $::openstack::params::nova_user_password,
  # General
  $verbose                       = $::openstack::params::verbose,
  $exported_resources            = $::openstack::params::exported_resources,
  $enabled                       = $::openstack::params::enabled
) inherits openstack::params {

  # Install / configure nova-compute
  class { '::nova::compute':
    enabled                       => true,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $vncserver_proxyclient_address,
    vncproxy_host                 => $vncproxy_host,
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type     => $libvirt_type,
    vncserver_listen => $vncserver_listen,
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
      enabled => $enabled,
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
  if $enable_network_service {
    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => false,  # double check
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => false,  # double check
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
        iscsi_ip_address => $internal_address,
      }
    }
  }

}
