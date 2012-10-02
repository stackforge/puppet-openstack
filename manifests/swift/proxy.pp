class openstack::swift::proxy (
  $swift_user_password              = 'swift_pass',
  $swift_hash_suffix                = 'swift_secret',
  $swift_local_net_ip               = $::ipaddress_eth0,
  $ring_part_power                  = 18,
  $ring_replicas                    = 3,
  $ring_min_part_hours              = 1,
  $proxy_pipeline                   = ['catch_errors', 'healthcheck', 'cache', 'ratelimit', 'swift3', 's3token', 'authtoken', 'keystone', 'proxy-server'],
  $proxy_workers                    = $::processorcount,
  $proxy_port                       = '8080',
  $proxy_allow_account_management   = true,
  $proxy_account_autocreate         = true,
  $ratelimit_clock_accuracy         = 1000,
  $ratelimit_max_sleep_time_seconds = 60,
  $ratelimit_log_sleep_time_seconds = 0,
  $ratelimit_rate_buffer_seconds    = 5,
  $ratelimit_account_ratelimit      = 0,
  $package_ensure                   = 'present',
  $controller_node_address          = '10.0.0.1',
  $memcached                        = true
) {

  class { 'swift': 
    swift_hash_suffix => $swift_hash_suffix,
    package_ensure    => $package_ensure,
  }

  if $memcached {
    class { 'memcached':
      listen_ip => '127.0.0.1',
    }
  }

  class { '::swift::proxy':
    proxy_local_net_ip       => $swift_local_net_ip,
    pipeline                 => $proxy_pipeline,
    port                     => $proxy_port,
    workers                  => $proxy_workers,
    allow_account_management => $proxy_allow_account_management,
    account_autocreate       => $proxy_account_autocreate,
    package_ensure           => $package_ensure,
    require                  => Class['swift::ringbuilder'],
  }

  # configure all of the middlewares
  class { [
    '::swift::proxy::catch_errors',
    '::swift::proxy::healthcheck',
    '::swift::proxy::cache',
    '::swift::proxy::swift3',
  ]: }

  class { '::swift::proxy::ratelimit':
    clock_accuracy         => $ratelimit_clock_accuracy,
    max_sleep_time_seconds => $ratelimit_max_sleep_time_seconds,
    log_sleep_time_seconds => $ratelimit_log_sleep_time_seconds,
    rate_buffer_seconds    => $ratelimit_rate_buffer_seconds,
    account_ratelimit      => $ratelimit_account_ratelimit,
  }

  class { '::swift::proxy::s3token':
    auth_host     => $controller_node_address,
    auth_port     => '35357',
  }
  class { '::swift::proxy::keystone':
    operator_roles => ['admin', 'SwiftOperator'],
  }
  class { '::swift::proxy::authtoken':
    admin_user        => 'swift',
    admin_tenant_name => 'services',
    admin_password    => $swift_user_password,
    auth_host         => $controller_node_address,
  }

  # collect all of the resources that are needed
  # to balance the ring
  Ring_object_device <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device <<| |>>

  # create the ring
  class { 'swift::ringbuilder':
    # the part power should be determined by assuming 100 partitions per drive
    part_power     => $ring_part_power,
    replicas       => $ring_replicas,
    min_part_hours => $ring_min_part_hours,
    require        => Class['swift'],
  }

  # sets up an rsync db that can be used to sync the ring DB
  class { 'swift::ringserver':
    local_net_ip => $swift_local_net_ip,
  }

  # exports rsync gets that can be used to sync the ring files
  @@swift::ringsync { ['account', 'object', 'container']:
   ring_server => $swift_local_net_ip
  }

  # deploy a script that can be used for testing
  file { '/tmp/swift_keystone_test.rb':
    source => 'puppet:///modules/swift/swift_keystone_test.rb'
  }
}
