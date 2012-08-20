#
# This class is intended to serve as
# a way of deploying compute nodes.
#
# This currently makes the following assumptions:
#   - libvirt is used to manage the hypervisors
#   - flatdhcp networking is used
#   - glance is used as the backend for the image service
#
# [private_interface] Interface used for vm networking connectivity. Required.
# [internal_address] Internal address used for management. Required.
# [public_interface] Public interface used to route public traffic. Optional.
#   Defaults to false.
# [fixed_range] Range of ipv4 network for vms.
# [network_manager] Nova network manager to use.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [sql_connection] SQL connection information. Optional. Defaults to false
#   which indicates that exported resources will be used to determine connection
#   information.
# [nova_user_password] Nova service password.
#  [rabbit_host] RabbitMQ host. False indicates it should be collected.
#    Optional. Defaults to false,
#  [rabbit_password] RabbitMQ password. Optional. Defaults to  'rabbit_pw',
#  [rabbit_user] RabbitMQ user. Optional. Defaults to 'nova',
#  [glance_api_servers] List of glance api servers of the form HOST:PORT
#    delimited by ':'. False indicates that the resource should be collected.
#    Optional. Defaults to false,
#  [libvirt_type] Underlying libvirt supported hypervisor.
#    Optional. Defaults to 'kvm',
#  [vncproxy_host] Host that serves as vnc proxy. Optional.
#    Defaults to false. False indicates that a vnc proxy should not be configured.
#  [vnc_enabled] Rather vnc console should be enabled.
#    Optional. Defaults to 'true',
#  [verbose] Rather components should log verbosely.
#    Optional. Defaults to false.
#  [manage_volumes] Rather nova-volume should be enabled on this compute node.
#    Optional. Defaults to false.
#  [nova_volumes] Name of volume group in which nova-volume will create logical volumes.
#    Optional. Defaults to nova-volumes.
#
class openstack::compute(
  $private_interface,
  $internal_address,
  # networking config
  $public_interface    = undef,
  $fixed_range         = '10.0.0.0/16',
  $network_manager     = 'nova.network.manager.FlatDHCPManager',
  $multi_host          = false,
  $network_config      = {},
  # my address
  # conection information
  $sql_connection      = false,
  $nova_user_password  = 'nova_pass',
  $rabbit_host         = false,
  $rabbit_password     = 'rabbit_pw',
  $rabbit_user         = 'nova',
  $glance_api_servers  = false,
  # nova compute configuration parameters
  $libvirt_type        = 'kvm',
  $vncproxy_host       = false,
  $vnc_enabled         = 'true',
  $verbose             = false,
  $manage_volumes      = false,
  $nova_volume         = 'nova-volumes'
) {

  warning('This class will be deprecated in favor of openstack::nova::compute')
  class { 'openstack::nova::compute':
    private_interface  => $private_interface,
    internal_address   => $internal_address,
    public_interface   => $public_interface,
    fixed_range        => $fixed_range,
    network_manager    => $network_manager,
    multi_host         => $multi_host,
    network_config     => $network_config,
    sql_connection     => $sql_connection,
    nova_user_password => $nova_user_password,
    rabbit_host        => $rabbit_host,
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    glance_api_servers => $glance_api_servers,
    libvirt_type       => $libvirt_type,
    vncproxy_host      => $vncproxy_host,
    vnc_enabled        => $vnc_enabled,
    verbose            => $verbose,
    manage_volumes     => $manage_volumes,
    nova_volume        => $nova_volume,
  }

}
