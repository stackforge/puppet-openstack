#
# == Class: openstack::horizon
#
# Class to install / configure horizon.
# Will eventually include apache and ssl.
#
# === Parameters
#
# See params.pp
#

class openstack::horizon (
  $secret_key        = $::openstack::params::secret_key,
  $cache_server_ip   = $::openstack::params::cache_server_ip,
  $cache_server_port = $::openstack::params::cache_server_port,
  $swift             = $::openstack::params::swift,
  $quantum           = $::openstack::params::quantum,
  $horizon_app_links = $::openstack::params::horizon_app_links
) {

  class { 'memcached':
    listen_ip => $cache_server_ip,
    tcp_port  => $cache_server_port,
    udp_port  => $cache_server_port,
  }

  class { '::horizon':
    secret_key        => $secret_key,
    swift             => $swift,
    quantum           => $quantum,
    horizon_app_links => $horizon_app_links,
  }
}
