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
# [swift] Set up swift endpoints and auth. Optional. Defaults to false
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
  $db_password,
  $admin_token,
  $admin_email,
  $admin_password,
  $glance_user_password,
  $nova_user_password,
  $cinder_user_password,
  $quantum_user_password,
  $swift_user_password      = false,
  $public_address,
  $db_type                  = 'mysql',
  $db_user                  = 'keystone',
  $db_name                  = 'keystone',
  $admin_tenant             = 'admin',
  $verbose                  = 'False',
  $bind_host                = '0.0.0.0',
  $region                   = 'RegionOne',
  $internal_address         = false,
  $admin_address            = false,
  $glance_public_address    = false,
  $glance_internal_address  = false,
  $glance_admin_address     = false,
  $nova_public_address      = false,
  $nova_internal_address    = false,
  $nova_admin_address       = false,
  $cinder_public_address    = false,
  $cinder_internal_address  = false,
  $cinder_admin_address     = false,
  $quantum_public_address   = false,
  $quantum_internal_address = false,
  $quantum_admin_address    = false,
  $swift_public_address     = false,
  $swift_internal_address   = false,
  $swift_admin_address      = false,
  $glance                   = true,
  $nova                     = true,
  $cinder                   = true,
  $quantum                  = true,
  $swift                    = false,
  $enabled                  = true
) {

  # Install and configure Keystone
  if $db_type == 'mysql' {
    $sql_conn = "mysql://${$db_user}:${db_password}@${db_host}/${db_name}"
  } else {
    fail("db_type ${db_type} is not supported")
  }

  # I have to do all of this crazy munging b/c parameters are not
  # set procedurally in Pupet
  if($internal_address) {
    $internal_real = $internal_address
  } else {
    $internal_real = $public_address
  }
  if($admin_address) {
    $admin_real = $admin_address
  } else {
    $admin_real = $internal_real
  }
  if($glance_public_address) {
    $glance_public_real = $glance_public_address
  } else {
    $glance_public_real = $public_address
  }
  if($glance_internal_address) {
    $glance_internal_real = $glance_internal_address
  } else {
    $glance_internal_real = $glance_public_real
  }
  if($glance_admin_address) {
    $glance_admin_real = $glance_admin_address
  } else {
    $glance_admin_real = $glance_internal_real
  }
  if($nova_public_address) {
    $nova_public_real = $nova_public_address
  } else {
    $nova_public_real = $public_address
  }
  if($nova_internal_address) {
    $nova_internal_real = $nova_internal_address
  } else {
    $nova_internal_real = $nova_public_real
  }
  if($nova_admin_address) {
    $nova_admin_real = $nova_admin_address
  } else {
    $nova_admin_real = $nova_internal_real
  }
  if($cinder_public_address) {
    $cinder_public_real = $cinder_public_address
  } else {
    $cinder_public_real = $public_address
  }
  if($cinder_internal_address) {
    $cinder_internal_real = $cinder_internal_address
  } else {
    $cinder_internal_real = $cinder_public_real
  }
  if($cinder_admin_address) {
    $cinder_admin_real = $cinder_admin_address
  } else {
    $cinder_admin_real = $cinder_internal_real
  }
  if($quantum_public_address) {
    $quantum_public_real = $quantum_public_address
  } else {
    $quantum_public_real = $public_address
  }
  if($quantum_internal_address) {
    $quantum_internal_real = $quantum_internal_address
  } else {
    $quantum_internal_real = $quantum_public_real
  }
  if($quantum_admin_address) {
    $quantum_admin_real = $quantum_admin_address
  } else {
    $quantum_admin_real = $quantum_internal_real
  }
  if($swift_public_address) {
    $swift_public_real = $swift_public_address
  } else {
    $swift_public_real = $public_address
  }
  if($swift_internal_address) {
    $swift_internal_real = $swift_internal_address
  } else {
    $swift_internal_real = $swift_public_real
  }
  if($swift_admin_address) {
    $swift_admin_real = $swift_admin_address
  } else {
    $swift_admin_real = $swift_internal_real
  }

  class { '::keystone':
    verbose        => $verbose,
    debug          => $verbose,
    catalog_type   => 'sql',
    admin_token    => $admin_token,
    enabled        => $enabled,
    sql_connection => $sql_conn,
  }

  if ($enabled) {
    # Setup the admin user
    class { 'keystone::roles::admin':
      email        => $admin_email,
      password     => $admin_password,
      admin_tenant => $admin_tenant,
    }

    # Setup the Keystone Identity Endpoint
    class { 'keystone::endpoint':
      public_address   => $public_address,
      admin_address    => $admin_real,
      internal_address => $internal_real,
      region           => $region,
    }

    # Configure Glance endpoint in Keystone
    if $glance {
      class { 'glance::keystone::auth':
        password         => $glance_user_password,
        public_address   => $glance_public_real,
        admin_address    => $glance_admin_real,
        internal_address => $glance_internal_real,
        region           => $region,
      }
    }

    # Configure Nova endpoint in Keystone
    if $nova {
      class { 'nova::keystone::auth':
        password         => $nova_user_password,
        public_address   => $nova_public_real,
        admin_address    => $nova_admin_real,
        internal_address => $nova_internal_real,
        region           => $region,
      }
    }

    # Configure Nova endpoint in Keystone
    if $cinder {
      class { 'cinder::keystone::auth':
        password         => $cinder_user_password,
        public_address   => $cinder_public_real,
        admin_address    => $cinder_admin_real,
        internal_address => $cinder_internal_real,
        region           => $region,
      }
    }
    if $quantum {
      class { 'quantum::keystone::auth':
        password         => $quantum_user_password,
        public_address   => $quantum_public_real,
        admin_address    => $quantum_admin_real,
        internal_address => $quantum_internal_real,
        region           => $region,
      }
    }

    if $swift {

      if ! $swift_user_password {
        fail('Must set a swift_user_password when swift auth is being configured')
      }

      class { 'swift::keystone::auth':
        password         => $swift_user_password,
        address          => $swift_public_real,
        region           => $region,
      }
    }
  }

}
