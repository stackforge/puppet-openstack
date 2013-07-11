class openstack::cinder::storage(
  $sql_connection,
  $rabbit_password,
  $rabbit_userid         = 'guest',
  $rabbit_host           = '127.0.0.1',
  $rabbit_hosts          = undef,
  $rabbit_port           = '5672',
  $rabbit_virtual_host   = '/',
  $package_ensure        = 'present',
  $api_paste_config      = '/etc/cinder/api-paste.ini',
  $volume_package_ensure = 'present',
  $volume_group          = 'cinder-volumes',
  $enabled               = true,
  $rbd_user              = 'volumes',
  $rbd_pool              = 'volumes',
  $volume_driver         = 'iscsi',
  $iscsi_ip_address      = '127.0.0.1',
  $setup_test_volume     = false,
  $verbose               = false
) {

  class {'::cinder':
    sql_connection      => $sql_connection,
    rabbit_userid       => $rabbit_userid,
    rabbit_password     => $rabbit_password,
    rabbit_host         => $rabbit_host,
    rabbit_port         => $rabbit_port,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_virtual_host => $rabbit_virtual_host,
    package_ensure      => $package_ensure,
    api_paste_config    => $api_paste_config,
    verbose             => $verbose,
  }


  class { '::cinder::volume':
    package_ensure => $volume_package_ensure,
    enabled        => $enabled,
  }

  case $volume_driver {

    'iscsi': {
      class { 'cinder::volume::iscsi':
        iscsi_ip_address => $iscsi_ip_address,
        volume_group     => $volume_group,
      }
      if $setup_test_volume {
        class {'::cinder::setup_test_volume':
          volume_name => $volume_group,
        }
      }
    }
    'rbd': {

      class { 'cinder::volume::rbd':
        rbd_user => $rbd_user,
        rbd_pool => $rbd_pool,
      }
    if $setup_test_volume {
      class {'::cinder::setup_test_volume':
        volume_name => $volume_group,
      }
    }
    }
    default:  {
      warning("Unsupported volume driver: ${volume_driver}, make sure you are configuring this yourself")
    }
  }
}
