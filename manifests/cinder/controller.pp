class openstack::cinder::controller(
  $cinder_sql_connection,
  $rabbit_password,
  $cinder_rpc_backend              = 'cinder.openstack.common.rpc.impl_kombu',
  $keystone_tenant                 = 'services',
  $keystone_enabled                = true,
  $keystone_user                   = 'cinder',
  $keystone_password               = 'cinder',
  $keystone_auth_host              = 'localhost',
  $keystone_auth_port              = '35357',
  $keystone_auth_protocol          = 'http',
  $keystone_service_port           = '5000',
  $rabbit_userid                   = 'guest',
  $rabbit_host                     = '127.0.0.1',
  $rabbit_hosts                    =  undef,
  $rabbit_port                     = '5672',
  $cinder_rabbit_virtual_host      = '/',
  $cinder_package_ensure           = 'present',
  $cinder_api_package_ensure       = 'latest',
  $cinder_scheduler_package_ensure = 'latest',
  $cinder_bind_host                = '0.0.0.0',
  $cinder_api_paste_config         = '/etc/cinder/api-paste.ini',
  $scheduler_driver                = 'cinder.scheduler.simple.SimpleScheduler',
  $cinder_api_enabled              =  true,
  $cinder_scheduler_enabled        =  true,
  $cinder_verbose                  = 'False'
) {

  class {'::cinder':
    sql_connection      => $cinder_sql_connection,
    rpc_backend         => $cinder_rpc_backend,
    rabbit_userid       => $rabbit_userid,
    rabbit_password     => $rabbit_password,
    rabbit_host         => $rabbit_host,
    rabbit_port         => $rabbit_port,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_virtual_host => $cinder_rabbit_virtual_host,
    package_ensure      => $cinder_package_ensure,
    api_paste_config    => $cinder_api_paste_config,
    verbose             => $cinder_verbose,
  }

  class {'::cinder::api':
    keystone_password       => $keystone_password,
    keystone_enabled        => $keystone_enabled,
    keystone_user           => $keystone_user,
    keystone_auth_host      => $keystone_auth_host,
    keystone_auth_port      => $keystone_auth_port,
    keystone_auth_protocol  => $keystone_auth_protocol,
    service_port            => $keystone_service_port,
    package_ensure          => $cinder_api_package_ensure,
    bind_host               => $cinder_bind_host,
    enabled                 => $cinder_api_enabled,
  }

  class {'::cinder::scheduler':
    scheduler_driver       => $scheduler_driver,
    package_ensure         => $cinder_scheduler_package_ensure,
    enabled                => $cinder_scheduler_enabled,
  }

}
