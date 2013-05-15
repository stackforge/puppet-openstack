#
# == Class: openstack::quantum
#
# Class to define quantum components for opensack. This class can
# be configured to provide all quantum related functionality.
#
# === Parameters
#
# [db_password]
#   (required) Password used to connect to quantum database.
#
# [bridge_interface]
#   (optional) Physical interface that ovs bridges its public traffic through.
#
# [external_bridge_name]
#    (optional) Name of external bridge that bridges to public interface.
#    Defaults to br-ex.
#
# === Examples
#
# class { 'openstack::quantum':
#   enable_l3_dhcp_agents => true,
#   enable_ovs_agent      => true,
#   db_host               => '127.0.0.1',
#   rabbit_password       => 'changeme',
#   bridge_interface      => 'eth0',
# }
#

class openstack::quantum (
  # Passwords
  $db_password,
  $user_password,
  $rabbit_password,
  # enable or disable quantum
  $enabled                = true,
  $enable_server          = true,
  # Set DHCP/L3 Agents on Primary Controller
  $enable_dhcp_agent      = false,
  $enable_l3_agent        = false,
  $enable_metadata_agent  = false,
  $enable_ovs_agent       = undef,
  # OVS settings
  $ovs_local_ip           = undef,
  $ovs_enable_tunneling   = true,
  # networking and Interface Information
  $bridge_interface       = undef,
  $external_bridge_name   = 'br-ex',
  # Quantum Authentication Information
  $l3_auth_url            = 'http://localhost:35357/v2.0',
  # Rabbit Information
  $rabbit_user            = 'quantum',
  $rabbit_host            = '127.0.0.1',
  $rabbit_virtual_host    = '/',
  # Database. Currently mysql is the only option.
  $db_type                = 'mysql',
  $db_host                = '127.0.0.1',
  $db_name                = 'quantum',
  $db_user                = 'quantum',
  # General
  $bind_address           = '0.0.0.0',
  $keystone_host          = '127.0.0.1',
  $verbose                = 'False',
  $debug                  = 'False',
  $enabled                = true
) {

  ####### DATABASE SETUP ######
  # set up mysql server
  if ($db_type == 'mysql') {
      $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?charset=utf8"
#    if ($enabled) {
#      # Ensure things are run in order
#      Class['quantum::db::mysql'] -> Class['quantum::plugins::ovs']
#      Class['quantum::db::mysql'] -> Class['quantum::agents::ovs']
#    }
  }

  class { '::quantum':
    enabled             => $enabled,
    bind_host           => $bind_address,
    rabbit_host         => $rabbit_host,
    rabbit_virtual_host => $rabbit_virtual_host,
    rabbit_user         => $rabbit_user,
    rabbit_password     => $rabbit_password,
    verbose             => $verbose,
    debug               => $debug,
  }

  if $enable_server {
    class { 'quantum::server':
      auth_host	    => $keystone_host,
      auth_password => $user_password,
    }
    class { 'quantum::plugins::ovs':
      sql_connection      => $sql_connection,
      tenant_network_type => 'gre',
    }
  }

  if $enable_ovs_agent {
    if ! $bridge_interface {
      fail('Bridge interface must be set when using ovs agent')
    }
    class { 'quantum::agents::ovs':
      bridge_uplinks   => ["${external_bridge_name}:${bridge_interface}"],
      bridge_mappings  => ["default:${external_bridge_name}"],
      enable_tunneling => $ovs_enable_tunneling,
      local_ip         => $ovs_local_ip,
    }
  }

  if $enable_dhcp_agent {
    class { 'quantum::agents::dhcp':
      use_namespaces => True
    }
  }
  if $enable_l3_agent {
    class {"quantum::agents::l3":
      use_namespaces => True
    }
  }

}
