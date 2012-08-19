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
