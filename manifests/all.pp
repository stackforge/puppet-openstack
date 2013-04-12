#
# == Class: openstack::all
#
# Class that performs a basic openstack all in one installation.
#
# === Parameters
#
#  [public_address] Public address used by vnchost. Required.
#  [public_interface] The interface used to route public traffic by the
#    network service.
#  [private_interface] The private interface used to bridge the VMs into a common network.
#  [floating_range] The floating ip range to be created. If it is false, then no floating ip range is created.
#    Optional. Defaults to false.
#  [fixed_range] The fixed private ip range to be created for the private VM network. Optional. Defaults to '10.0.0.0/24'.
#  [network_manager] The network manager to use for the nova network service.
#    Optional. Defaults to 'nova.network.manager.FlatDHCPManager'.
#  [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
#  [network_config] Used to specify network manager specific parameters .Optional. Defualts to {}.
#  [mysql_root_password] The root password to set for the mysql database. Optional. Defaults to sql_pass'.
#  [rabbit_password] The password to use for the rabbitmq user. Optional. Defaults to rabbit_pw'
#  [rabbit_user] The rabbitmq user to use for auth. Optional. Defaults to nova'.
#  [admin_email] The admin's email address. Optional. Defaults to someuser@some_fake_email_address.foo'.
#  [admin_password] The default password of the keystone admin. Optional. Defaults to ChangeMe'.
#  [keystone_db_password] The default password for the keystone db user. Optional. Defaults to keystone_pass'.
#  [keystone_admin_token] The default auth token for keystone. Optional. Defaults to keystone_admin_token'.
#  [nova_db_password] The nova db password. Optional. Defaults to nova_pass'.
#  [nova_user_password] The password of the keystone user for the nova service. Optional. Defaults to nova_pass'.
#  [glance_db_password] The password for the db user for glance. Optional. Defaults to 'glance_pass'.
#  [glance_user_password] The password of the glance service user. Optional. Defaults to 'glance_pass'.
#  [secret_key] The secret key for horizon. Optional. Defaults to 'dummy_secret_key'.
#  [verbose] If the services should log verbosely. Optional. Defaults to false.
#  [purge_nova_config] Whether unmanaged nova.conf entries should be purged. Optional. Defaults to true.
#  [libvirt_type] The virualization type being controlled by libvirt.  Optional. Defaults to 'kvm'.
#  [nova_volume] The name of the volume group to use for nova volume allocation. Optional. Defaults to 'nova-volumes'.
#  [horizon] (bool) is horizon installed. Defaults to: true
# === Examples
#
#  class { 'openstack::all':
#    public_address       => '192.168.1.1',
#    mysql_root_password  => 'changeme',
#    rabbit_password      => 'changeme',
#    keystone_db_password => 'changeme',
#    keystone_admin_token => '12345',
#    admin_email          => 'my_email@mw.com',
#    admin_password       => 'my_admin_password',
#    nova_db_password     => 'changeme',
#    nova_user_password   => 'changeme',
#    glance_db_password   => 'changeme',
#    glance_user_password => 'changeme',
#    secret_key           => 'dummy_secret_key',
#  }
#
# === Authors
#
# Dan Bode <bodepd@gmail.com>
#
#
class openstack::all (
  # Required Network
  $public_address,
  $public_interface,
  $private_interface,
  $admin_email,
  # required password
  $mysql_root_password,
  $admin_password,
  $rabbit_password,
  $keystone_db_password,
  $keystone_admin_token,
  $glance_db_password,
  $glance_user_password,
  $nova_db_password,
  $nova_user_password,
  $secret_key,
  $internal_address = '127.0.0.1',
  # cinder and quantum password are not required b/c they are
  # optional. Not sure what to do about this.
  $cinder_user_password    = 'cinder_pass',
  $cinder_db_password      = 'cinder_pass',
  $quantum_user_password   = 'quantum_pass',
  $quantum_db_password     = 'quantum_pass',
  # Database
  $db_type                 = 'mysql',
  $mysql_account_security  = true,
  $allowed_hosts           = ['127.0.0.%'],
  # Keystone
  $keystone_db_user        = 'keystone',
  $keystone_db_dbname      = 'keystone',
  $keystone_admin_tenant   = 'admin',
  $region                  = 'RegionOne',
  # Glance Required
  $glance_db_user          = 'glance',
  $glance_db_dbname        = 'glance',
  # Nova
  $nova_db_user            = 'nova',
  $nova_db_dbname          = 'nova',
  $purge_nova_config       = true,
  # Network
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $fixed_range             = '10.0.0.0/24',
  $floating_range          = false,
  $create_networks         = true,
  $num_networks            = 1,
  $auto_assign_floating_ip = false,
  $network_config          = {},
  $quantum                 = true,
  # Rabbit
  $rabbit_user             = 'nova',
  # Horizon
  $horizon                 = true,
  $cache_server_ip         = '127.0.0.1',
  $cache_server_port       = '11211',
  $swift                   = false,
  $horizon_app_links       = undef,
  # if the cinder management components should be installed
  $cinder                  = true,
  $cinder_db_user          = 'cinder',
  $cinder_db_dbname        = 'cinder',
  $volume_group            = 'cinder-volumes',
  $cinder_test             = false,
  #
  $quantum_db_user         = 'quantum',
  $quantum_db_dbname       = 'quantum',
  # Virtaulization
  $libvirt_type            = 'kvm',
  # VNC
  $vnc_enabled             = true,
  # General
  $enabled                 = true,
  $verbose                 = 'False'
) {

  # Ensure things are run in order
  Class['openstack::db::mysql'] -> Class['openstack::keystone']
  Class['openstack::db::mysql'] -> Class['openstack::glance']

  # set up mysql server
  if ($db_type == 'mysql') {
    if ($enabled) {
      Class['glance::db::mysql'] -> Class['glance::registry']
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@127.0.0.1/nova?charset=utf8"
    } else {
      $nova_db = false
    }
    class { 'openstack::db::mysql':
      mysql_root_password    => $mysql_root_password,
      mysql_account_security => $mysql_account_security,
      keystone_db_user       => $keystone_db_user,
      keystone_db_password   => $keystone_db_password,
      keystone_db_dbname     => $keystone_db_dbname,
      glance_db_user         => $glance_db_user,
      glance_db_password     => $glance_db_password,
      glance_db_dbname       => $glance_db_dbname,
      nova_db_user           => $nova_db_user,
      nova_db_password       => $nova_db_password,
      nova_db_dbname         => $nova_db_dbname,
      cinder                 => $cinder,
      cinder_db_user         => $cinder_db_user,
      cinder_db_password     => $cinder_db_password,
      cinder_db_dbname       => $cinder_db_dbname,
      quantum                => $quantum,
      quantum_db_user        => $quantum_db_user,
      quantum_db_password    => $quantum_db_password,
      quantum_db_dbname      => $quantum_db_dbname,
      allowed_hosts          => $allowed_hosts,
      enabled                => $enabled,
    }
  } else {
    fail("unsupported db type: ${db_type}")
  }

  ####### KEYSTONE ###########
  class { 'openstack::keystone':
    verbose                   => $verbose,
    db_type                   => $db_type,
    db_host                   => '127.0.0.1',
    db_password               => $keystone_db_password,
    db_name                   => $keystone_db_dbname,
    db_user                   => $keystone_db_user,
    admin_token               => $keystone_admin_token,
    admin_tenant              => $keystone_admin_tenant,
    admin_email               => $admin_email,
    admin_password            => $admin_password,
    public_address            => $public_address,
    internal_address          => '127.0.0.1',
    admin_address             => '127.0.0.1',
    region                    => $region,
    glance_user_password      => $glance_user_password,
    nova_user_password        => $nova_user_password,
    cinder                    => $cinder,
    cinder_user_password      => $cinder_user_password,
    quantum                   => $quantum,
    quantum_user_password     => $quantum_user_password,
  }

  ######## GLANCE ##########
  class { 'openstack::glance':
    verbose                   => $verbose,
    db_type                   => $db_type,
    db_host                   => '127.0.0.1',
    glance_db_user            => $glance_db_user,
    glance_db_dbname          => $glance_db_dbname,
    glance_db_password        => $glance_db_password,
    glance_user_password      => $glance_user_password,
    enabled                   => $enabled,
  }

  ######## NOVA ###########

  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }

  # Install / configure rabbitmq
  class { 'nova::rabbitmq':
    userid   => $rabbit_user,
    password => $rabbit_password,
    enabled  => $enabled,
  }

  # Configure Nova
  class { 'nova':
    sql_connection     => $nova_db,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => 'localhost:9292',
    verbose            => $verbose,
    rabbit_host        => '127.0.0.1',
  }

  # Configure nova-api
  class { 'nova::api':
    enabled           => $enabled,
    admin_password    => $nova_user_password,
    auth_host         => 'localhost',
  }

  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
  }

  if $quantum == false {
    # Configure nova-network
    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => $floating_range,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => $really_create_networks,
      num_networks      => $num_networks,
      enabled           => $enabled,
    }
  } else {
    # Set up Quantum
    $quantum_sql_connection = "mysql://${quantum_db_user}:${quantum_db_password}@127.0.0.1/${quantum_db_dbname}?charset=utf8"

    class { 'quantum':
      verbose         => $verbose,
      debug           => $verbose,
      rabbit_host     => '127.0.0.1',
      rabbit_user     => $rabbit_user,
      rabbit_password => $rabbit_password,
    }

    class { 'quantum::server':
      auth_password => $quantum_user_password,
    }

    class { 'quantum::agents::dhcp': }

    class { 'nova::compute::quantum': }

    nova_config {
      'DEFAULT/linuxnet_interface_driver':       value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
      'DEFAULT/linuxnet_ovs_integration_bridge': value => 'br-int';
    }

    class { 'quantum::plugins::ovs':
      sql_connection      => $quantum_sql_connection,
      tenant_network_type => 'gre',
      # I need to know what this does...
      local_ip            => '10.0.0.1',
      enable_tunneling    => true,
    }

    class { 'quantum::agents::ovs':
      bridge_uplinks => ["br-virtual:${private_interface}"],
    }

    class { 'nova::network::quantum':
    #$fixed_range,
      quantum_admin_password    => $quantum_user_password,
    #$use_dhcp                  = 'True',
    #$public_interface          = undef,
      quantum_connection_host   => 'localhost',
      quantum_auth_strategy     => 'keystone',
      quantum_url               => "http://127.0.0.1:9696",
      quantum_admin_tenant_name => 'services',
      #quantum_admin_username    => 'quantum',
      quantum_admin_auth_url    => "http://127.0.0.1:35357/v2.0",
    }
  }

  if $auto_assign_floating_ip {
    nova_config { 'DEFUALT/auto_assign_floating_ip': value => 'True' }
  }

  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::cert',
    'nova::consoleauth'
  ]:
    enabled => $enabled,
  }

  if $vnc_enabled {
    class { 'nova::vncproxy':
      host          => $public_address,
      enabled       => $enabled,
    }
  }

  ######### Cinder Controller Services ########
  if ($cinder) {
    class { "cinder::base":
      verbose         => $verbose,
      sql_connection  => "mysql://${cinder_db_user}:${cinder_db_password}@127.0.0.1/${cinder_db_dbname}?charset=utf8",
      rabbit_password => $rabbit_password,
    }

    class { 'cinder::api':
      keystone_password => $cinder_user_password,
    }

    class { 'cinder::scheduler': }
    class { 'cinder::volume': }
    class { 'cinder::volume::iscsi':
      iscsi_ip_address => '127.0.0.1',
      volume_group     => $nova_volume,
    }
  } else {
    # Set up nova-volume
  }

  # Install / configure nova-compute
  class { '::nova::compute':
    enabled                       => $enabled,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $internal_address,
    vncproxy_host                 => $public_address,
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type     => $libvirt_type,
    vncserver_listen => $internal_address,
  }

  ######## Horizon ########
  if ($horizon) {
    class { 'openstack::horizon':
      secret_key        => $secret_key,
      cache_server_ip   => $cache_server_ip,
      cache_server_port => $cache_server_port,
      swift             => $swift,
      quantum           => $quantum,
      horizon_app_links => $horizon_app_links,
    }
  }

}
