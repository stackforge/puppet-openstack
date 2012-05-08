#
# This can be used to build out the simplest openstack controller
#
#
# $export_resources - rather resources should be exported
#

class openstack::controller(
  # my address
  $public_address,
  $internal_address,
  $admin_address           = $internal_address,
  # connection information
  $mysql_root_password     = 'sql_pass',
  $admin_email             = 'some_user@some_fake_email_address.foo',
  $admin_password          = 'ChangeMe',
  $keystone_db_password    = 'keystone_pass',
  $keystone_admin_token    = 'keystone_admin_token',
  $glance_db_password      = 'glance_pass',
  $glance_service_password = 'glance_pass',
  $nova_db_password        = 'nova_pass',
  $nova_service_password   = 'nova_pass',
  $rabbit_password         = 'rabbit_pw',
  $rabbit_user             = 'nova',
  # network configuration
  # this assumes that it is a flat network manager
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  # I do not think that this needs a bridge?
  $bridge_ip               = '192.168.188.1',
  $bridge_netmask          = '255.255.255.0',
  $verbose                 = false,
  $export_resource         = false
) {

  $glance_api_servers = "${internal_address}:9292"
  $nova_db = "mysql://nova:${nova_db_password}@${internal_address}/nova"

  if ($export_resources) {
    # export all of the things that will be needed by the clients
    @@nova_config { 'rabbit_host': value => $internal_address }
    Nova_config <| title == 'rabbit_host' |>
    @@nova_config { 'sql_connection': value => $nova_db }
    Nova_config <| title == 'sql_connection' |>
    @@nova_config { 'glance_api_servers': value => $glance_api_servers }
    Nova_config <| title == 'glance_api_servers' |>
    @@nova_config { 'novncproxy_base_url': value => "http://${public_address}:6080/vnc_auto.html" }
    $sql_connection    = false
    $glance_connection = false
    $rabbit_connection = false
  } else {
    $sql_connection    = $nova_db
    $glance_connection = $glance_api_servers
    $rabbit_connection = $rabbit_host
  }

  ####### DATABASE SETUP ######

  # set up mysql server
  class { 'mysql::server':
    config_hash => {
      # the priv grant fails on precise if I set a root password
      # TODO I should make sure that this works
      # 'root_password' => $mysql_root_password,
      'bind_address'  => '0.0.0.0'
    }
  }
  # set up all openstack databases, users, grants
  class { 'keystone::db::mysql':
    password => $keystone_db_password,
  }
  class { 'glance::db::mysql':
    host     => '127.0.0.1',
    password => $glance_db_password,
  }
  # TODO should I allow all hosts to connect?
  class { 'nova::db::mysql':
    password      => $nova_db_password,
    host          => $internal_address,
    allowed_hosts => '%',
  }

  ####### KEYSTONE ###########

  # set up keystone
  class { 'keystone':
    admin_token  => $keystone_admin_token,
    # we are binding keystone on all interfaces
    # the end user may want to be more restrictive
    bind_host    => '0.0.0.0',
    log_verbose  => $verbose,
    log_debug    => $verbose,
    catalog_type => 'sql',
  }
  # set up keystone database
  # set up the keystone config for mysql
  class { 'keystone::config::mysql':
    password => $keystone_db_password,
  }
  # set up keystone admin users
  class { 'keystone::roles::admin':
    email    => $admin_email,
    password => $admin_password,
  }
  # set up the keystone service and endpoint
  class { 'keystone::endpoint':
    public_address   => $public_address,
    internal_address => $internal_address,
    admin_address    => $admin_address 
  }
  # set up glance service,user,endpoint
  class { 'glance::keystone::auth':
    password         => $glance_service_password,
    public_address   => $public_address,
    internal_address => $internal_address,
    admin_address    => $admin_address 
  }
  # set up nova serice,user,endpoint
  class { 'nova::keystone::auth':
    password => $nova_service_password,
    public_address   => $public_address,
    internal_address => $internal_address,
    admin_address    => $admin_address 
  }

  ######## END KEYSTONE ##########

  ######## BEGIN GLANCE ##########


  class { 'glance::api':
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    auth_host         => '127.0.0.1',
    auth_port         => '35357',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_service_password,
    require => Keystone_user_role["glance@services"],
  }
  class { 'glance::backend::file': }

  class { 'glance::registry':
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    auth_host         => '127.0.0.1',
    auth_port         => '35357',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_service_password,
    sql_connection    => "mysql://glance:${glance_db_password}@127.0.0.1/glance",
    require           => [Class['Glance::Db::Mysql'], Keystone_user_role['glance@services']]
  }

  ######## END GLANCE ###########

  ######## BEGIN NOVA ###########


  class { 'nova::rabbitmq':
    userid   => $rabbit_user,
    password => $rabbit_password,
  }

  # TODO I may need to figure out if I need to set the connection information
  # or if I should collect it
  class { 'nova':
    sql_connection     => $sql_connection,
    # this is false b/c we are exporting
    rabbit_host        => $rabbit_connection,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_connection,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
  }

  class { 'nova::api':
    enabled           => true,
    # TODO this should be the nova service credentials
    #admin_tenant_name => 'openstack',
    #admin_user        => 'admin',
    #admin_password    => $admin_service_password,
    admin_tenant_name => 'services',
    admin_user        => 'nova',
    admin_password    => $nova_service_password,
    require => Keystone_user_role["nova@services"],
  }

  class { [
    'nova::cert',
    'nova::consoleauth',
    'nova::scheduler',
    'nova::network',
    'nova::objectstore',
    'nova::vncproxy'
  ]:
    enabled => true,
  }

  nova::manage::network { 'nova-vm-net':
    network       => '11.0.0.0/24',
  }

  nova::manage::floating { 'nova-vm-floating':
    network       => '10.128.0.0/24',
  }

  ######## Horizon ########

  class { 'memcached':
    listen_ip => '127.0.0.1',
  }

  class { 'horizon': }


  ######## End Horizon #####

}
