#
# == Class: openstack::quantum
#
# Class to define quantum components for openstack. This class can
# be configured to provide all quantum related functionality.
#
# === Parameters
#
# [user_password]
#   Password used for authentication.
#  (required)
#
# [rabbit_password]
#   Password used to connect to rabbitmq
#   (required)
#
# [enabled]
#   state of the quantum services.
#   (optional) Defaults to true.
#
# [enable_server]
#   If the server should be installed.
#   (optional) Defaults to true.
#
# [enable_dhcp_agent]
#   Whether the dhcp agent should be enabled.
#   (optional) Defaults to false.
#
# [enable_l3_agent]
#   Whether the l3 agent should be enabled.
#   (optional) Defaults to false.
#
# [enable_metadata_agent]
#   Whether the metadata agent should be enabled.
#   (optional) Defaults to false.
#
# [enable_ovs_agent]
#   Whether the ovs agent should be enabled.
#   (optional) Defaults to false.
#
# [bridge_uplinks]
#   OVS external bridge name and physical bridge interface tuple.
#   (optional) Defaults to [].
#
# [bridge_mappings]
#   Physical network name and OVS external bridge name tuple. Only needed for flat and VLAN networking.
#   (optional) Defaults to [].
#
# [auth_url]
#   Url used to contact the authentication service.
#   (optional) Defaults to 'http://localhost:35357/v2.0'.
#
# [shared_secret]
#    Shared secret used for the metadata service.
#    (optional) Defaults to false indicating the metadata service is not configured.
#
# [metadata_ip]
#    Ip address of metadata service.
#    (optional) Defaults to '127.0.0.1'.
#
# [db_password]
#   Password used to connect to quantum database.
#   (required)
#
# [db_type]
#   Type of database to use. Only accepts mysql at the moment.
#   (optional)
#
# [ovs_local_ip]
#   Ip address to use for tunnel endpoint.
#   Only required when ovs is enabled. No default.
#
# [ovs_enable_tunneling]
#    Whether ovs tunnels should be enabled.
#    (optional) Defaults to true.
#
# [firewall_driver]
#   Firewall driver to use.
#   (optional) Defaults to undef.
#
# [rabbit_user]
#   Name of rabbit user.
#   (optional) defaults to rabbit_user.
#
# [rabbit_host]
#   Host where rabbitmq is running.
#   (optional) 127.0.0.1
#
# [rabbit_hosts]
#   Enable/disable Qauntum to use rabbitmq mirrored queues.
#   Specifies an array of clustered rabbitmq brokers.
#   (optional) false
#
# [rabbit_virtual_host]
#   Virtual host to use for rabbitmq.
#   (optional) Defaults to '/'.
#
# [db_host]
#   Host where db is running.
#   (optional) Defaults to 127.0.0.1.
#
# [db_name]
#   Name of quantum database.
#   (optional) Defaults to quantum.
#
# [db_user]
#   User to connect to quantum database as.
#   (optional) Defaults to quantum.
#
# [bind_address]
#   Address quantum api server should bind to.
#  (optional) Defaults to 0.0.0.0.
#
# [keystone_host]
#   Host running keystone.
#   (optional) Defaults to 127.0.0.1.
#
# [verbose]
#   Enables verbose for quantum services.
#   (optional) Defaults to false.
#
# [debug]
#   Enables debug for quantum services.
#   (optional) Defaults to false.
#
# === Examples
#
# class { 'openstack::quantum':
#   db_password           => 'quantum_db_pass',
#   user_password         => 'keystone_user_pass',
#   rabbit_password       => 'quantum_rabbit_pass',
#   bridge_uplinks        => '[br-ex:eth0]',
#   bridge_mappings       => '[default:br-ex],
#   enable_ovs_agent      => true,
#   ovs_local_ip          => '10.10.10.10',
# }
#

class openstack::quantum (
  # Passwords
  $user_password,
  $rabbit_password,
  # enable or disable quantum
  $enabled                = true,
  $enable_server          = true,
  # Set DHCP/L3 Agents on Primary Controller
  $enable_dhcp_agent      = false,
  $enable_l3_agent        = false,
  $enable_metadata_agent  = false,
  $enable_ovs_agent       = false,
  # OVS settings
  $ovs_local_ip           = false,
  $ovs_enable_tunneling   = true,
  $bridge_uplinks         = [],
  $bridge_mappings        = [],
  # rely on the default set in ovs
  $firewall_driver       = undef,
  # networking and Interface Information
  # Metadata configuration
  $shared_secret          = false,
  $metadata_ip            = '127.0.0.1',
  # Quantum Authentication Information
  $auth_url               = 'http://localhost:35357/v2.0',
  # Rabbit Information
  $rabbit_user            = 'rabbit_user',
  $rabbit_host            = '127.0.0.1',
  $rabbit_hosts           = false,
  $rabbit_virtual_host    = '/',
  # Database. Currently mysql is the only option.
  $db_type                = 'mysql',
  $db_password            = false,
  $db_host                = '127.0.0.1',
  $db_name                = 'quantum',
  $db_user                = 'quantum',
  # General
  $bind_address           = '0.0.0.0',
  $keystone_host          = '127.0.0.1',
  $verbose                = false,
  $debug                  = false,
) {

  class { '::quantum':
    enabled             => $enabled,
    bind_host           => $bind_address,
    rabbit_host         => $rabbit_host,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_virtual_host => $rabbit_virtual_host,
    rabbit_user         => $rabbit_user,
    rabbit_password     => $rabbit_password,
    verbose             => $verbose,
    debug               => $debug,
  }

  if $enable_server {
    if ! $db_password {
      fail('db password must be set when configuring a quantum server')
    }
    if ($db_type == 'mysql') {
      $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?charset=utf8"
    } else {
      fail("Unsupported db type: ${db_type}. Only mysql is currently supported.")
    }
    class { 'quantum::server':
      auth_host     => $keystone_host,
      auth_password => $user_password,
    }
    class { 'quantum::plugins::ovs':
      sql_connection      => $sql_connection,
      tenant_network_type => 'gre',
    }
  }

  if $enable_ovs_agent {
    if ! $ovs_local_ip {
      fail('ovs_local_ip parameter must be set when using ovs agent')
    }
    class { 'quantum::agents::ovs':
      bridge_uplinks   => $bridge_uplinks,
      bridge_mappings  => $bridge_mappings,
      enable_tunneling => $ovs_enable_tunneling,
      local_ip         => $ovs_local_ip,
      firewall_driver  => $firewall_driver,
    }
  }

  if $enable_dhcp_agent {
    class { 'quantum::agents::dhcp':
      use_namespaces => true,
    }
  }
  if $enable_l3_agent {
    class { 'quantum::agents::l3':
      use_namespaces => true,
    }
  }

  if $enable_metadata_agent {
    if ! $shared_secret {
      fail('metadata_shared_secret parameter must be set when using metadata agent')
    }
    class { 'quantum::agents::metadata':
      auth_password  => $user_password,
      shared_secret  => $shared_secret,
      auth_url       => $auth_url,
      metadata_ip    => $metadata_ip,
    }
  }

}
