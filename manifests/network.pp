#
# == Class: openstack::network
#
# Manifest to install/configure a network node.
# A network node runs Quantum services but does not run nova-compute.
#
# === Parameters
#
# [internal_address]
#   Internal address used for management.
#   Required.
#
# [quantum_user_password] 
#   Auth password for Quantum.
#   Required.
#
# [enable_ovs_agent]
#   Boolean indicating whether to enable the OVS plugin agent.
#   Optional.  Defaults to true.
#
# [enable_l3_agent]
#   Boolean indicating whether to enable the Quantum L3 agent.
#   Optional.  Defaults to true.
#
# [enable_dhcp_agent]
#   Boolean indicating whether to enable the Quantum DHCP agent.
#   Optional.  Defaults to true.
#
# [quantum_auth_url]
#   URL used by Quantum to contact the authentication service.
#   Optional.  Defaults to http://127.0.0.1:35357/v2.0.
#
# [keystone_host]
#   The IP or hostname on which Keystone is running.
#   Optional.  Defaults to 127.0.0.1.
#
# [quantum_host]
#   The IP or hostname on which Quantum is running.
#   Optional.  Defaults to 127.0.0.1.
#
# [ovs_enable_tunneling]
#   Boolean indicating whether to enable the Quantum OVS GRE 
#   tunneling networking mode.
#   Optional.  Defaults to true.
#
# [ovs_local_ip]
#   Ip address to use for tunnel endpoint.
#   Only required when using GRE tunneling.  No default.
#
# [bridge_mappings]
#   Physical network name and OVS external bridge name tuple. Only
#   needed for flat and VLAN networking.
#   Optional.  Defaults to undef.
#
# [bridge_uplinks]
#   OVS external bridge name and physical bridge interface tuple.
#   Optional.  Defaults to undef.
#
# [rabbit_password]
#   Password used to connect to RabbitMQ.
#   Required.
#
# [rabbit_host]
#   Host where RabbitMQ is running.
#   Optional.  Defaults to 127.0.0.1.
#
# [rabbit_user]
#   Name of rabbit user.
#   Optional.  Defaults to 'openstack'.
#
# [db_host]
#   Host where the database is running.
#   Optional.  Defaults to 127.0.0.1.
#
# [verbose]
#   Enables verbose mode for Quantum services.
#   Optional.  Defaults to false.
#
# [enabled]
#   Boolean indicating whether Quantum services should be enabled.
#   Optional.  Defaults to true.
#
# === Examples
#
# class { 'openstack::network':
#   internal_address      => '192.168.1.2',
#   quantum_user_password => 'openstack',
#   enable_ovs_agent      => true,
#   enable_l3_agent       => true,
#   enable_dhcp_agent     => true,
#   keystone_auth_url     => '192.168.1.1',
#   ovs_local_ip          => '192.168.1.2',
#   rabbit_password       => 'openstack',
#   rabbit_host           => '192.168.1.1',
#   rabiit_user           => 'openstack',
#   db_host               => '192.168.1.1'
# }

class openstack::network (
  # Quantum
  $internal_address              = false,
  $quantum_user_password         = false,
  $enable_ovs_agent              = true,
  $enable_l3_agent               = false,
  $enable_dhcp_agent             = false,
  $quantum_auth_url              = 'http://127.0.0.1:35357/v2.0',
  $keystone_host                 = '127.0.0.1',
  $quantum_host                  = '127.0.0.1',
  $ovs_enable_tunneling          = true,
  $ovs_local_ip                  = false,
  $bridge_mappings               = undef,
  $bridge_uplinks                = undef,
  # Rabbit
  $rabbit_password,
  $rabbit_host                   = '127.0.0.1',
  $rabbit_user                   = 'openstack',
  # DB
  $db_host                       = '127.0.0.1',
  # General
  $verbose                       = false,
  $enabled                       = true
) {

  # Use $internal_address for $ovs_local_ip if the latter
  # isn't actually specified.
  if $ovs_local_ip {
    $ovs_local_ip_real = $ovs_local_ip
  } else {
    $ovs_local_ip_real = $internal_address
  }

  class { 'openstack::quantum':
    # Database
    db_host              => $db_host,
    # Networking
    ovs_local_ip         => $ovs_local_ip_real,
    bridge_mappings      => $bridge_mappings,
    bridge_uplinks       => $bridge_uplinks,
    # Rabbit
    rabbit_host          => $rabbit_host,
    rabbit_user          => $rabbit_user,
    rabbit_password      => $rabbit_password,
    # Quantum OVS
    enable_ovs_agent     => $enable_ovs_agent,
    ovs_enable_tunneling => $ovs_enable_tunneling,
    # Quantum L3 Agent
    enable_l3_agent      => $enable_l3_agent,
    enable_dhcp_agent    => $enable_dhcp_agent,
    auth_url             => $quantum_auth_url,
    user_password        => $quantum_user_password,
    # Keystone
    keystone_host        => $keystone_host,
    # General
    enabled              => $enabled,
    enable_server        => false,
    verbose              => $verbose,
  }
}
