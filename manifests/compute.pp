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
  $public_interface              = undef,
  $private_interface             = undef,
  $fixed_range                   = undef,
  $network_manager               = 'nova.network.manager.FlatDHCPManager',
  $network_config                = {},
  $multi_host                    = false,
  $enabled_apis                  = 'ec2,osapi_compute,metadata',
  # Quantum
  $quantum                       = false,
  $quantum_host                  = false,
  $quantum_user_password         = false,
  $keystone_host                 = false,
  # Nova
  $nova_admin_tenant_name        = 'services',
  $nova_admin_user               = 'nova',
  $purge_nova_config             = true,
  # Rabbit
  $rabbit_host                   = '127.0.0.1',
  $rabbit_user                   = 'nova',
  $rabbit_virtual_host           = '/',
  # Glance
  $glance_api_servers            = false,
  # Virtualization
  $libvirt_type                  = 'kvm',
  # VNC
  $vnc_enabled                   = true,
  $vncproxy_host                 = undef,
  $vncserver_listen              = false,
  # cinder / volumes
  $cinder                        = true,
  $cinder_sql_connection         = undef,
  $manage_volumes                = true,
  $volume_group                  = 'cinder-volumes',
  $iscsi_ip_address              = '127.0.0.1',
  # General
  $migration_support             = false,
  $verbose                       = 'False',
  $enabled                       = true
) {

  if $vncserver_listen {
    $vncserver_listen_real = $vncserver_listen
  } else {
    $vncserver_listen_real = $internal_address
  }


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
    sql_connection      => $sql_connection,
    rabbit_userid       => $rabbit_user,
    rabbit_password     => $rabbit_password,
    image_service       => 'nova.image.glance.GlanceImageService',
    glance_api_servers  => $glance_api_servers,
    verbose             => $verbose,
    rabbit_host         => $rabbit_host,
    rabbit_virtual_host => $rabbit_virtual_host,
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
    vncserver_listen  => $vncserver_listen_real,
    migration_support => $migration_support,
  }

  # if the compute node should be configured as a multi-host
  # compute installation
  if ! $quantum {

    if ! $fixed_range {
      fail("Must specify the fixed range when using nova-networks")
    }

    if $multi_host {
      include keystone::python
      nova_config {
        'DEFAULT/multi_host':      value => 'True';
        'DEFAULT/send_arp_for_ha': value => 'True';
      }
      if ! $public_interface {
        fail('public_interface must be defined for multi host compute nodes')
      }
      $enable_network_service = true
      class { 'nova::api':
        enabled           => true,
        admin_tenant_name => $nova_admin_tenant_name,
        admin_user        => $nova_admin_user,
        admin_password    => $nova_user_password,
        enabled_apis      => $enabled_apis,
      }
    } else {
      $enable_network_service = false
      nova_config {
        'DEFAULT/multi_host':      value => 'False';
        'DEFAULT/send_arp_for_ha': value => 'False';
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

    if ! $quantum_host {
      fail('quantum host must be specified when quantum is installed on compute instances')
    }
    if ! $quantum_user_password {
      fail('quantum user password must be set when quantum is configured')
    }
    if ! $keystone_host {
      fail('keystone host must be configured when quantum is installed')
    }

    class { 'quantum':
      verbose         => $verbose,
      debug           => $verbose,
      rabbit_host     => $rabbit_host,
      rabbit_user     => $rabbit_user,
      rabbit_password => $rabbit_password,
      #sql_connection  => $quantum_sql_connection,
    }

    class { 'quantum::agents::ovs':
      enable_tunneling => true,
      local_ip         => $internal_address,
    }

    class { 'nova::compute::quantum': }

    # does this have to be installed on the compute node?
    # NOTE
    class { 'nova::network::quantum':
      quantum_admin_password    => $quantum_user_password,
      quantum_auth_strategy     => 'keystone',
      quantum_url               => "http://${keystone_host}:9696",
      quantum_admin_tenant_name => 'services',
      quantum_admin_username    => 'quantum',
      quantum_admin_auth_url    => "http://${keystone_host}:35357/v2.0"
    }

    nova_config {
      'DEFAULT/linuxnet_interface_driver':       value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
      'DEFAULT/linuxnet_ovs_integration_bridge': value => 'br-int';
    }
  }

  if ($cinder) {
    class { 'cinder::base':
      rabbit_password => $rabbit_password,
      rabbit_host     => $rabbit_host,
      sql_connection  => $cinder_sql_connection,
      verbose         => $verbose,
    }
    class { 'cinder::volume': }
    class { 'cinder::volume::iscsi':
      iscsi_ip_address => $iscsi_ip_address,
      volume_group     => $volume_group,
    }

    # set in nova::api
    if ! defined(Nova_config['DEFAULT/volume_api_class']) {
      nova_config { 'DEFAULT/volume_api_class': value => 'nova.volume.cinder.API' }
    }
  } else {
    # Set up nova-volume
  }

}
