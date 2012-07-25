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
# === Examples
#
# class { 'openstack::horizon': 
#   secret_key => 'dummy_secret_key',
# }
#

class openstack::horizon (
  $cache_server_ip   = '127.0.0.1',
  $cache_server_port = '11211',
  $swift             = false,
  $quantum           = false,
  $horizon_app_links = undef,
  $secret_key
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
