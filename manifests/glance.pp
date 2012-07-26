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
#   db_host              => '127.0.0.1',
# }

class openstack::glance (
  $keystone_host,
  $db_host,
  $glance_user_password,
  $glance_db_password,
  $db_type              = 'mysql',
  $glance_db_user       = 'glance',
  $glance_db_dbname     = 'glance',
  $verbose              = false,
  $enabled              = true
) {

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
    auth_port         => '35357',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    enabled           => $enabled,
  }

  # Install and configure glance-registry
  class { 'glance::registry':
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_host         => $keystone_host,
    auth_port         => '35357',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    sql_connection    => $sql_connection,
    enabled           => $enabled,
  }

  # Configure file storage backend
  class { 'glance::backend::file': }

}
