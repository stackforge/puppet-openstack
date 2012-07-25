#
# == Class: openstack::nova::compute
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
  # Network
  $public_address                = undef,
  $public_interface              = 'eth0',
  $private_interface             = 'eth1',
  $fixed_range                   = '10.0.0.0/24',
  $network_manager               = 'nova.network.manager.FlatDHCPManager',
  $network_config                = {},
  $multi_host                    = false,
  # Virtualization
  $libvirt_type                  = 'kvm',
  # Volumes
  $nova_volume                   = 'nova-volumes',
  $manage_volumes                = true,
  $iscsi_ip_address              = undef,
  # VNC
  $vnc_enabled                   = true,
  $vncserver_listen              = undef,
  $vncserver_proxyclient_address = undef,
  $vncproxy_host                 = undef,
  # General
  $verbose                       = false,
  $exported_resources            = true,
  $enabled                       = true,
  # Required Network
  $internal_address,
  # Required Nova
  $nova_user_password
) inherits openstack::params {

  # Set iscsi ip address if not set
  if ($iscsi_ip_address == undef) {
    $real_iscsi_ip_address = $internal_address
  } else {
    $real_iscsi_ip_address = $iscsi_ip_address
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

  # Install / configure nova-compute
  class { '::nova::compute':
    enabled                       => true,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $real_vncserver_proxyclient_address,
    vncproxy_host                 => $real_vncproxy_host,
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type     => $libvirt_type,
    vncserver_listen => $real_vncserver_listen,
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
