#
# == Class: openstack::horizon
#
# Class to install / configure horizon.
# Will eventually include apache and ssl.
#
# NOTE: Will the inclusion of memcache be an issue?
#       Such as if the server already has memcache installed?
#       -jtopjian
#
# === Parameters
#
# [*secret_key*]
#   (required) A secret key for a particular Django installation. This is used to provide cryptographic signing,
#   and should be set to a unique, unpredictable value.
#
# [*cache_server_ip*]
#   (optional) Ip address where the memcache server is listening.
#   Defaults to '127.0.0.1'.
#
# [*cache_server_port*]
#    (optional) Port that memcache server listens on.
#    Defaults to '11211'.
#
# [*horizon_app_links*]
#   (optional) External Monitoring links.
#   Defaults to undef.
#
# [*keystone_host*]
#   (optional) Address of keystone host.
#   Defaults to '127.0.0.1'.
#
# [*keystone_scheme*]
#    (optional) Protocol for keystone. Accepts http or https.
#    Defaults to http.
#
# [*keystone_default_role*]
#   (Optional) Default role for keystone authentication.
#   Defaults to 'Member'.
#
# [*django_debug*]
#    (Optional) Sets Django debug level.
#    Defaults to false.
#
# [*api_result_limit*]
#    (Optional) Maximum results to show on a page before pagination kicks in.
#    Defaults to 1000.
#
# === Examples
#
# class { 'openstack::horizon':
#   secret_key => 'dummy_secret_key',
# }
#

class openstack::horizon (
  $secret_key,
  $cache_server_ip       = '127.0.0.1',
  $cache_server_port     = '11211',
  $horizon_app_links     = undef,
  $keystone_host         = '127.0.0.1',
  $keystone_scheme       = 'http',
  $keystone_default_role = 'Member',
  $django_debug          = 'False',
  $api_result_limit      = 1000
) {

  class { 'memcached':
    listen_ip => $cache_server_ip,
    tcp_port  => $cache_server_port,
    udp_port  => $cache_server_port,
  }

  class { '::horizon':
    cache_server_ip       => $cache_server_ip,
    cache_server_port     => $cache_server_port,
    secret_key            => $secret_key,
    horizon_app_links     => $horizon_app_links,
    keystone_host         => $keystone_host,
    keystone_scheme       => $keystone_scheme,
    keystone_default_role => $keystone_default_role,
    django_debug          => $django_debug,
    api_result_limit      => $api_result_limit,
  }
}
