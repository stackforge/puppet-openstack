#
# == Class: openstack::keystone
#
# Installs and configures Keystone
#
# === Parameters
# 
# See params.pp
#
# === Example
#
# class { 'openstack::keystone':
#   db_password      => 'changeme',
#   admin_token      => '12345',
#   admin_email      => 'root@localhost',
#   admin_password   => 'changeme',
#   public_address   => '192.168.1.1',
#   admin_addresss   => '192.168.1.1',
#   internal_address => '192.168.1.1',
#  }

class openstack::keystone (
  $db_type               = $::openstack::params::db_type,
  $db_host               = $::openstack::params::db_host,
  $keystone_db_user      = $::openstack::params::keystone_db_user,
  $keystone_db_password  = $::openstack::params::keystone_db_password,
  $keystone_db_dbname    = $::openstack::params::keystone_db_dbname,
  $keystone_admin_tenant = $::openstack::params::keystone_admin_tenant,
  $keystone_admin_token  = $::openstack::params::keystone_admin_token,
  $admin_email           = $::openstack::params::admin_email,
  $admin_password        = $::openstack::params::admin_password,
  $public_address        = $::openstack::params::public_address,
  $admin_address         = $::openstack::params::admin_address,
  $internal_address      = $::openstack::params::internal_address,
  $verbose               = $::openstack::params::verbose
) inherits openstack::params {

  # Install and configure Keystone
  class { '::keystone':
    log_verbose  => $verbose,
    log_debug    => $verbose,
    catalog_type => 'sql',
    admin_token  => $keystone_admin_token,
  }

  # Setup the admin user
  class { 'keystone::roles::admin':
    email        => $admin_email,
    password     => $admin_password,
    admin_tenant => $keystone_admin_tenant,
  }

  # Setup the Keystone Identity Endpoint
  class { 'keystone::endpoint':
    public_address   => $public_address,
    admin_address    => $admin_address,
    internal_address => $internal_address,
  }

  # Configure the Keystone database
  case $db_type {

    'mysql': {
      class { 'keystone::config::mysql':
        user     => $keystone_db_user,
        password => $keystone_db_password,
        host     => $db_host,
        dbname   => $keystone_db_dbname,
      }
    }

  }

}
