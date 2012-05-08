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
  # my address
  $internal_address,
  # conection information
  $sql_connection     = false,
  $rabbit_host        = false,
  $rabbit_password    = 'rabbit_pw',
  $rabbit_user        = 'nova',
  $glance_api_servers = false,
  $vncproxy_host      = false,
  # nova compute configuration parameters
  $libvirt_type       = 'kvm',
  $vnc_enabled        = 'true',
  $bridge_ip          = '11.0.0.1',
  $bridge_netmask     = '255.255.255.0',
) {

  class { 'nova':
    sql_connection     => $sql_connection,
    rabbit_host        => $rabbit_host,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_api_servers,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
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

  nova::network::bridge { 'br100':
    ip      => $bridge_ip,
    netmask => $bridge_netmask,
  }

}
