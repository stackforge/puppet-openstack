#
# == Class: openstack::keystone
#
# Installs and configures Keystone
#
# === Parameters
#
# [db_host] Host where DB resides. Required.
# [keystone_db_password] Password for keystone DB. Required.
# [keystone_admin_token]. Auth token for keystone admin. Required.
# [admin_email] Email address of system admin. Required.
# [admin_password] 
# [glance_user_password] Auth password for glance user. Required.
# [nova_user_password] Auth password for nova user. Required.
# [public_address] Public address where keystone can be accessed. Required.
# [db_type] Type of DB used. Currently only supports mysql. Optional. Defaults to  'mysql'
# [keystone_db_user] Name of keystone db user. Optional. Defaults to  'keystone'
# [keystone_db_dbname] Name of keystone DB. Optional. Defaults to  'keystone'
# [keystone_admin_tenant] Name of keystone admin tenant. Optional. Defaults to  'admin'
# [verbose] Log verbosely. Optional. Defaults to  'False'
# [bind_host] Address that keystone binds to. Optional. Defaults to  '0.0.0.0'
# [internal_address] Internal address for keystone. Optional. Defaults to  $public_address
# [admin_address] Keystone admin address. Optional. Defaults to  $internal_address
# [glance] Set up glance endpoints and auth. Optional. Defaults to  true
# [nova] Set up nova endpoints and auth. Optional. Defaults to  true
# [enabled] If the service is active (true) or passive (false).
#   Optional. Defaults to  true
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
  $db_host,
  $keystone_db_password,
  $keystone_admin_token,
  $admin_email,
  $admin_password,
  $glance_user_password,
  $nova_user_password,
  $public_address,
  $db_type               = 'mysql',
  $keystone_db_user      = 'keystone',
  $keystone_db_dbname    = 'keystone',
  $keystone_admin_tenant = 'admin',
  $verbose               = 'False',
  $bind_host             = '0.0.0.0',
  $admin_address         = $public_address,
  $internal_address      = $public_address,
  $glance                = true,
  $nova                  = true,
  $enabled               = true,
) {

  # Install and configure Keystone
  class { '::keystone':
    log_verbose  => $verbose,
    log_debug    => $verbose,
    catalog_type => 'sql',
    admin_token  => $keystone_admin_token,
    enabled      => $enabled,
  }

  if ($enabled) {
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

    # Configure Glance endpoint in Keystone
    if $glance {
      class { 'glance::keystone::auth':
        password         => $glance_user_password,
        public_address   => $public_address,
        admin_address    => $admin_address,
        internal_address => $internal_address,
      }
    }

    # Configure Nova endpoint in Keystone
    if $nova {
      class { 'nova::keystone::auth':
        password         => $nova_user_password,
        public_address   => $public_address,
        admin_address    => $admin_address,
        internal_address => $internal_address,
      }
    }
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
