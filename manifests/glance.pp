#
# == Class: openstack::glance
#
# Installs and configures Glance
# Assumes the following:
#   - Keystone for authentication
#   - keystone tenant: services
#   - keystone username: glance
#   - storage backend: file (default) or Swift
#
# === Parameters
#
# [user_password] Password for glance auth user. Required.
# [db_password] Password for glance DB. Required.
# [db_host] Host where DB resides. Required.
# [keystone_host] Host whre keystone is running. Optional. Defaults to '127.0.0.1'
# [sql_idle_timeout] Timeout for SQL to reap connections. Optional. Defaults to '3600'
# [db_type] Type of sql databse to use. Optional. Defaults to 'mysql'
# [db_user] Name of glance DB user. Optional. Defaults to 'glance'
# [db_name] Name of glance DB. Optional. Defaults to 'glance'
# [backend] Backends used to store images.  Defaults to file.
# [swift_store_user] The Swift service user account. Defaults to false.
# [swift_store_key]  The Swift service user password Defaults to false.
# [swift_store_auth_addres] The URL where the Swift auth service lives. Defaults to "http://${keystone_host}:5000/v2.0/"
# [verbose] Log verbosely. Optional. Defaults to false.
# [debug] Log at a debug-level. Optional. Defaults to false.
# [enabled] Used to indicate if the service should be active (true) or passive (false).
#   Optional. Defaults to true
#
# === Example
#
# class { 'openstack::glance':
#   user_password => 'changeme',
#   db_password   => 'changeme',
#   db_host       => '127.0.0.1',
# }

class openstack::glance (
  $user_password,
  $db_password,
  $db_host                  = '127.0.0.1',
  $keystone_host            = '127.0.0.1',
  $sql_idle_timeout         = '3600',
  $db_type                  = 'mysql',
  $db_user                  = 'glance',
  $db_name                  = 'glance',
  $backend                  = 'file',
  $swift_store_user         = false,
  $swift_store_key          = false,
  $swift_store_auth_address = 'http://127.0.0.1:5000/v2.0/',
  $verbose                  = false,
  $debug                    = false,
  $enabled                  = true
) {

  # Configure the db string
  if $db_type == 'mysql' {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}"
  } else {
    fail("Unsupported db_type ${db_type}. Only mysql is currently supported")
  }

  # Install and configure glance-api
  class { 'glance::api':
    verbose           => $verbose,
    debug             => $debug,
    auth_type         => 'keystone',
    auth_port         => '35357',
    auth_host         => $keystone_host,
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $user_password,
    sql_connection    => $sql_connection,
    sql_idle_timeout  => $sql_idle_timeout,
    enabled           => $enabled,
  }

  # Install and configure glance-registry
  class { 'glance::registry':
    verbose           => $verbose,
    debug             => $debug,
    auth_host         => $keystone_host,
    auth_port         => '35357',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $user_password,
    sql_connection    => $sql_connection,
    enabled           => $enabled,
  }

  # Configure file storage backend
  if($backend == 'swift') {

    if ! $swift_store_user {
      fail('swift_store_user must be set when configuring swift as the glance backend')
    }
    if ! $swift_store_key {
      fail('swift_store_key must be set when configuring swift as the glance backend')
    }

    class { 'glance::backend::swift':
      swift_store_user                    => $swift_store_user,
      swift_store_key                     => $swift_store_key,
      swift_store_auth_address            => $swift_store_auth_address,
      swift_store_create_container_on_put => true,
    }
  } elsif($backend == 'file') {
  # Configure file storage backend
    class { 'glance::backend::file': }
  } else {
    fail("Unsupported backend ${backend}")
  }

}
