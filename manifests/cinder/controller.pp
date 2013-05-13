class openstack::cinder::controller(
  $sql_connection,
  $rabbit_password,
  $keystone_password,
  $rpc_backend              = 'cinder.openstack.common.rpc.impl_kombu',
  $keystone_tenant          = 'services',
  $keystone_enabled         = true,
  $keystone_user            = 'cinder',
  $keystone_auth_host       = 'localhost',
  $keystone_auth_port       = '35357',
  $keystone_auth_protocol   = 'http',
  $keystone_service_port    = '5000',
  $rabbit_userid            = 'guest',
  $rabbit_host              = '127.0.0.1',
  $rabbit_hosts             =  undef,
  $rabbit_port              = '5672',
  $rabbit_virtual_host      = '/',
  $package_ensure           = present,
  $api_package_ensure       = present,
  $scheduler_package_ensure = present,
  $bind_host                = '0.0.0.0',
  $api_paste_config         = '/etc/cinder/api-paste.ini',
  $scheduler_driver         = 'cinder.scheduler.simple.SimpleScheduler',
  $api_enabled              = true,
  $scheduler_enabled        = true,
  $verbose                  = false
) {

  class {'::cinder':
    sql_connection      => $sql_connection,
    rpc_backend         => $rpc_backend,
    rabbit_userid       => $rabbit_userid,
    rabbit_password     => $rabbit_password,
    rabbit_host         => $rabbit_host,
    rabbit_port         => $rabbit_port,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_virtual_host => $cinder_rabbit_virtual_host,
    package_ensure      => $package_ensure,
    api_paste_config    => $api_paste_config,
    verbose             => $verbose,
  }

  class {'::cinder::api':
    keystone_password       => $keystone_password,
    keystone_enabled        => $keystone_enabled,
    keystone_user           => $keystone_user,
    keystone_auth_host      => $keystone_auth_host,
    keystone_auth_port      => $keystone_auth_port,
    keystone_auth_protocol  => $keystone_auth_protocol,
    service_port            => $keystone_service_port,
    package_ensure          => $api_package_ensure,
    bind_host               => $bind_host,
    enabled                 => $api_enabled,
  }

  class {'::cinder::scheduler':
    scheduler_driver       => $scheduler_driver,
    package_ensure         => $scheduler_package_ensure,
    enabled                => $scheduler_enabled,
  }

}
