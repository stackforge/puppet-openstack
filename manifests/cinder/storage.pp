class openstack::cinder::storage(
  $sql_connection,
  $rabbit_password,
  $rabbit_userid                  = 'guest',
  $rabbit_host                    = '127.0.0.1',
  $rabbit_hosts                   = undef,
  $rabbit_port                    = '5672',
  $rabbit_virtual_host            = '/',
  $cinder_package_ensure          = 'present',
  $api_paste_config               = '/etc/cinder/api-paste.ini',
  $cinder_package_ensure          = 'latest',
  $cinder_volume_package_ensure   = 'latest',
  $volume_group                   = 'cinder-volumes',
  $cinder_volume_enabled          = true,
  $iscsi_enabled                  = true,
  $iscsi_ip_address               = '127.0.0.1',
  $setup_test_volume              = true,
  $cinder_verbose                 = 'False',
) {

  class {'::cinder':
    sql_connection      => $cinder_sql_connection,
    rabbit_userid       => $rabbit_userid,
    rabbit_password     => $rabbit_password,
    rabbit_host         => $rabbit_host,
    rabbit_port         => $rabbit_port,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_virtual_host => $rabbit_virtual_host,
    package_ensure      => $cinder_package_ensure,
    api_paste_config    => $cinder_api_paste_config,
    verbose             => $cinder_verbose,
  }


  class { '::cinder::volume':
    package_ensure          => $cinder_volume_package_ensure,
    enabled                 => $cinder_volume_enabled,
  }
  if $iscsi_enabled {
    class { '::cinder::volume::iscsi':
      iscsi_ip_address => $iscsi_ip_address,
      volume_group     => $volume_group,
    }
  }
  if $setup_test_volume {
    class {'::cinder::setup_test_volume':}
   }
}
