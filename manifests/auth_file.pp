#
# Creates an auth file that can be used to export
# environment variables that can be used to authenticate
# against a keystone server.
#
class openstack::auth_file(
  $admin_password       = $::openstack::params::admin_password,
  $public_address       = $::openstack::params::public_address,
  $keystone_admin_token = $::openstack::params::keystone_admin_token,
  $admin_tenant         = $::openstack::params::keystone_admin_tenant,
  $admin_user           = 'admin'
) {
  file { '/root/openrc':
    content =>
  "
  export OS_TENANT_NAME=${admin_tenant}
  export OS_USERNAME=${admin_user}
  export OS_PASSWORD=${admin_password}
  export OS_AUTH_URL=\"http://${public_address}:5000/v2.0/\"
  export OS_AUTH_STRATEGY=keystone
  export SERVICE_TOKEN=${keystone_admin_token}
  export SERVICE_ENDPOINT=http://${public_address}:35357/v2.0/
  "
  }
}
