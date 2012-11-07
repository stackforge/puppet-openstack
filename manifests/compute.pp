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
  # Quantum
  $quantum                       = false,
  $quantum_sql_connection        = false,
  $quantum_host                  = false,
  $quantum_user_password         = false,
  $keystone_host                 = false,
  # Nova
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
  $nova_volume                   = 'cinder-volumes',
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

    if ! $quantum_sql_connection {
      fail('quantum sql connection must be specified when quantum is installed on compute instances')
    }
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

    class { 'quantum::plugins::ovs':
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

    class { 'quantum::agents::l3':
      auth_password => $quantum_user_password,
    }

    class { 'nova::compute::quantum': }

    # does this have to be installed on the compute node?
    # NOTE
    class { 'nova::network::quantum':
    #$fixed_range,
      quantum_admin_password    => $quantum_user_password,
    #$use_dhcp                  = 'True',
    #$public_interface          = undef,
      quantum_connection_host   => $quantum_host,
      #quantum_auth_strategy     => 'keystone',
      quantum_url               => "http://${keystone_host}:9696",
      quantum_admin_tenant_name => 'services',
      #quantum_admin_username    => 'quantum',
      quantum_admin_auth_url    => "http://${keystone_host}:35357/v2.0"
    }

    nova_config {
      'linuxnet_interface_driver':       value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
      'linuxnet_ovs_integration_bridge': value => 'br-int';
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
      iscsi_ip_address => $internal_address,
      volume_group     => $nova_volume,
    }

    # set in nova::api
    if ! defined(Nova_config['volume_api_class']) {
      nova_config { 'volume_api_class': value => 'nova.volume.cinder.API' }
    }
  } else {
    # Set up nova-volume
  }

}
