#
# This class is intended to serve as
# a way of deploying compute nodes.
#
# This currently makes the following assumptions:
#   - libvirt is used to manage the hypervisors
#   - flatdhcp networking is used
#   - glance is used as the backend for the image service
#
# TODO - I need to make the choise of networking configurable
#
class openstack::compute(
  $private_interface,
  $internal_address,
  # networking config
  $public_interface    = undef,
  $fixed_range         = '10.0.0.0/16',
  $network_manager     = 'nova.network.manager.FlatDHCPManager',
  $multi_host          = false,
  $network_host        = false,
  $network_config      = {},
  # my address
  # conection information
  $sql_connection      = false,
  $rabbit_host         = false,
  $rabbit_password     = 'rabbit_pw',
  $rabbit_user         = 'nova',
  $glance_api_servers  = false,
  # nova compute configuration parameters
  $libvirt_type        = 'kvm',
  $vncproxy_host       = false,
  $vnc_enabled         = 'true',
  $verbose             = false
) {

  class { 'nova':
    sql_connection     => $sql_connection,
    rabbit_host        => $rabbit_host,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_api_servers,
    verbose            => $verbose,
  }

  class { 'nova::compute':
    enabled                        => true,
    vnc_enabled                    => $vnc_enabled,
    vncserver_proxyclient_address  => $internal_address,
    vncproxy_host                  => $vncproxy_host,
  }

  class { 'nova::compute::libvirt':
    libvirt_type     => $libvirt_type,
    vncserver_listen => $internal_address,
  }

  # if the compute node should be configured as a multi-host
  # compute installation
  if $multi_host {

    include keystone::python

    nova_config { 'multi_host':   value => 'True'; }
    if ! $public_interface {
      fail('public_interface must be defined for multi host compute nodes')
    }
    $enable_network_service = true
    class { 'nova::api':
      enabled           => true,
      admin_tenant_name => 'services',
      admin_user        => 'nova',
      admin_password    => $nova_service_password,
    }
  } else {
    $enable_network_service = false
    if ! $network_host {
      fail('network_host must be defined for non multi host compute nodes')
    }
    nova_config {
      'multi_host':   value => 'False';
      'network_host': value => $network_host;
    }
  }

  # set up configuration for networking
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
