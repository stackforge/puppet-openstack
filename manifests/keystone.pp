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
#   db_host               => '127.0.0.1',
#   keystone_db_password  => 'changeme',
#   keystone_admin_token  => '12345',
#   admin_email           => 'root@localhost',
#   admin_password        => 'changeme',
#   public_address        => '192.168.1.1',
#  }

class openstack::keystone (
  $db_type               = 'mysql',
  $keystone_db_user      = 'keystone',
  $keystone_db_dbname    = 'keystone',
  $keystone_admin_tenant = 'admin',
  $admin_address         = undef,
  $internal_address      = undef,
  $verbose               = false,
  $db_host,
  $keystone_db_password,
  $keystone_admin_token,
  $admin_email,
  $admin_password,
  $public_address
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
    admin_address    => $real_admin_address,
    internal_address => $real_internal_address,
  }

  # Configure Glance to use Keystone
  class { 'glance::keystone::auth':
    password         => $glance_user_password,
    public_address   => $public_address,
    admin_address    => $real_admin_address,
    internal_address => $real_internal_address,
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
