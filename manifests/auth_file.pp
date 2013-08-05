#
# Creates an auth file that can be used to export
# environment variables that can be used to authenticate
# against a keystone server.
#
class openstack::auth_file(
  $controller_node          = '127.0.0.1',
  $keystone_admin_token     = undef,
  $admin_user               = 'admin',
  $admin_password           = undef,
  $admin_tenant             = 'admin',
  $region_name              = 'RegionOne',
  $use_no_cache             = true,
  $ceilometer_endpoint_type = 'publicURL',
  $cinder_endpoint_type     = 'publicURL',
  $glance_endpoint_type     = 'publicURL',
  $heat_endpoint_type       = 'publicURL',
  $keystone_endpoint_type   = 'publicURL',
  $nova_endpoint_type       = 'publicURL',
  $quantum_endpoint_type    = 'publicURL',
) {

  file { '/root/openrc':
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template("${module_name}/openrc.erb")
  }
}
