class openstack::cinder::storage(
  $rabbit_password,
  $db_password,
  $rabbit_userid         = 'guest',
  $rabbit_host           = '127.0.0.1',
  $rabbit_hosts          = undef,
  $rabbit_port           = '5672',
  $rabbit_virtual_host   = '/',
  # Database. Currently mysql is the only option.
  $db_type               = 'mysql',
  $db_user               = 'cinder',
  $db_host               = '127.0.0.1',
  $db_dbname             = 'cinder',
  $package_ensure        = 'present',
  $api_paste_config      = '/etc/cinder/api-paste.ini',
  $volume_package_ensure = 'present',
  $volume_group          = 'cinder-volumes',
  $enabled               = true,
  $volume_driver         = 'iscsi',
  $iscsi_ip_address      = '127.0.0.1',
  $setup_test_volume     = false,
  $verbose               = false
) {

  ####### DATABASE SETUP ######
  # set up mysql server
  if ($db_type == 'mysql') {
    $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_dbname}?charset=utf8"
  } else {
    fail("Unsupported db_type ${db_type}")
  }

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

  if $volume_driver == 'iscsi' {
    class { 'cinder::volume::iscsi':
      iscsi_ip_address => $iscsi_ip_address,
      volume_group     => $volume_group,
    }
    if $setup_test_volume {
      class {'::cinder::setup_test_volume':
        volume_name => $volume_group,
      }
    }
  } else {
    warning("Unsupported volume driver: ${volume_driver}, make sure you are configuring this yourself")
  }
}
