#
# == Class: openstack::compute
#
# Manifest to install/configure nova-compute
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

class openstack::compute (
  # Required Network
  $internal_address,
  # Required Nova
  $nova_user_password,
  # Required Rabbit
  $rabbit_password,
  # DB
  $sql_connection,
  # Network
  $quantum                       = true,
  $public_address                = $internal_address,
  $admin_address                 = $internal_address,
  $public_interface              = undef,
  $private_interface             = undef,
  $fixed_range                   = undef,
  $network_manager               = 'nova.network.manager.FlatDHCPManager',
  $network_config                = {},
  $multi_host                    = false,
  # Nova
  $purge_nova_config             = true,
  # Rabbit
  $rabbit_host                   = '127.0.0.1',
  $rabbit_user                   = 'nova',
  # Glance
  $glance_api_servers            = false,
  # Virtualization
  $libvirt_type                  = 'kvm',
  # VNC
  $vnc_enabled                   = true,
  $vncproxy_host                 = undef,
  $vncserver_listen              = $internal_address,
  # cinder / volumes
  $cinder                        = true,
  $cinder_sql_connection         = undef,
  $manage_volumes                = true,
  $nova_volume                   = 'cinder-volumes',
  $iscsi_ip_address              = '127.0.0.1',
  # General
  $migration_support             = false,
  $verbose                       = 'False',
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

  class { 'nova':
    sql_connection     => $sql_connection,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_api_servers,
    verbose            => $verbose,
    rabbit_host        => $rabbit_host,
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
    libvirt_type      => $libvirt_type,
    vncserver_listen  => $vncserver_listen,
    migration_support => $migration_support,
  }

  # if the compute node should be configured as a multi-host
  # compute installation
  if $quantum == false {
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
        # TODO override enabled_apis
      }
    } else {
      $enable_network_service = false
      nova_config {
        'multi_host':      value => 'False';
        'send_arp_for_ha': value => 'False';
      }
    }

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
  } else {
    # TODO install quantum
  }

  if ($cinder) {
    class { 'cinder':
      rabbit_password => $rabbit_password,
      rabbit_host     => $rabbit_host,
      sql_connection  => $cinder_sql_connection,
      verbose         => $verbose,
    }
    class { 'cinder::volume': }
    class { 'cinder::volume::iscsi': }
  } else {
    # Set up nova-volume
  }

}
