#
# === Class: openstack::db::mysql
#
# Create MySQL databases for all components of
# OpenStack that require a database
#
# === Parameters
#
# See params.pp
#
# === Example
#
# class { 'openstack::db::mysql':
#    mysql_root_password       => 'changeme',
#    keystone_db_password => 'changeme',
#    glance_db_password   => 'changeme',
#    nova_db_password     => 'changeme',
#    allowed_hosts        => ['127.0.0.1', '10.0.0.%'],
#  }


class openstack::db::mysql (
    # MySQL
    $mysql_bind_address     = $::openstack::params::mysql_bind_address,
    $allowed_hosts          = $::openstack::params::mysql_allowed_hosts,
    $mysql_root_password    = $::openstack::params::mysql_root_password,
    $mysql_account_security = $::openstack::params::mysql_account_security,
    # Keystone
    $keystone_db_user       = $::openstack::params::keystone_db_user,
    $keystone_db_dbname     = $::openstack::params::keystone_db_dbname,
    $keystone_db_password   = $::openstack::params::keystone_db_password,
    # Glance
    $glance_db_user         = $::openstack::params::glance_db_user,
    $glance_db_dbname       = $::openstack::params::glance_db_dbname,
    $glance_db_password     = $::openstack::params::glance_db_password,
    # Nova
    $nova_db_user           = $::openstack::params::nova_db_user,
    $nova_db_dbname         = $::openstack::params::nova_db_dbname,
    $nova_db_password       = $::openstack::params::nova_db_password
) {

  # Install and configure MySQL Server
  class { 'mysql::server': 
    config_hash => { 
      'root_password' => $mysql_root_password,
      'bind_address'  => $mysql_bind_address,
    }
  }

  # If enabled, secure the mysql installation
  # This removes default users and guest access
  if $mysql_account_security {
    class { 'mysql::server::account_security': }
  }

  # Create the Keystone db
  class { 'keystone::db::mysql':
    user          => $keystone_db_user,
    password      => $keystone_db_password,
    dbname        => $keystone_db_dbname,
    allowed_hosts => $allowed_hosts,
  }

  # Create the Glance db
  class { 'glance::db::mysql':
    user          => $glance_db_user,
    password      => $glance_db_password,
    dbname        => $glance_db_dbname,
    allowed_hosts => $allowed_hosts,
  }

  # Create the Nova db
  class { 'nova::db::mysql':
    user          => $nova_db_user,
    password      => $nova_db_password,
    dbname        => $nova_db_dbname,
    allowed_hosts => $allowed_hosts,
  }
}
