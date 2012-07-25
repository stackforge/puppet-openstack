#
# == Class: openstack::glance
#
# Installs and configures Glance
# Assumes the following:
#   - Keystone for authentication
#   - keystone tenant: services
#   - keystone username: glance
#   - storage backend: file
#
# === Parameters
#
# See params.pp
#
# === Example
#
# class { 'openstack::glance':
#   glance_user_password => 'changeme',
#   db_password          => 'changeme',
#   public_address       => '192.168.1.1',
#   db_host              => '127.0.0.1',
# }

class openstack::glance (
  $db_type              = 'mysql',
  $glance_db_user       = 'glance',
  $glance_db_dbname     = 'glance',
  $admin_address        = undef,
  $internal_address     = undef,
  $verbose              = false,
  $db_host,
  $glance_user_password,
  $glance_db_password,
  $public_address,
) inherits openstack::params {

  # Configure admin_address and internal address if needed.
  if (admin_address == undef) {
    $real_admin_address = $public_address
  } else {
    $real_admin_address = $admin_address
  }

  if (internal_address == undef) {
    $real_internal_address = $public_address
  } else {
    $real_internal_address = $internal_address
  }

  # Configure the db string
  case $db_type {
    'mysql': {
      $sql_connection = "mysql://${glance_db_user}:${glance_db_password}@${db_host}/${glance_db_dbname}"
    }
  }

  # Install and configure glance-api
  class { 'glance::api':
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
  }

  # Install and configure glance-registry
  class { 'glance::registry':
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    sql_connection    => $sql_connection,
  }

  # Configure file storage backend
  class { 'glance::backend::file': }

  # Configure Glance to use Keystone
  class { 'glance::keystone::auth':
    password         => $glance_user_password,
    public_address   => $public_address,
    admin_address    => $real_admin_address,
    internal_address => $real_internal_address,
  }

}
