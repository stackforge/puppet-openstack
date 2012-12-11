#
# This can be used to build out the simplest openstack controller
#
# === Parameters
#
# [public_interface] Public interface used to route public traffic. Required.
# [public_address] Public address for public endpoints. Required.
# [private_interface] Interface used for vm networking connectivity. Required.
# [internal_address] Internal address used for management. Required.
# [mysql_root_password] Root password for mysql server.
# [admin_email] Admin email.
# [admin_password] Admin password.
# [keystone_db_password] Keystone database password.
# [keystone_admin_token] Admin token for keystone.
# [glance_db_password] Glance DB password.
# [glance_user_password] Glance service user password.
# [nova_db_password] Nova DB password.
# [nova_user_password] Nova service password.
# [rabbit_password] Rabbit password.
# [rabbit_user] Rabbit User.
# [rabbit_virtual_host] Rabbit virtual host path for Nova. Defaults to '/'.
# [network_manager] Nova network manager to use.
# [fixed_range] Range of ipv4 network for vms.
# [floating_range] Floating ip range to create.
# [create_networks] Rather network and floating ips should be created.
# [num_networks] Number of networks that fixed range should be split into.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [verbose] Whether to log services at verbose.
# Horizon related config - assumes puppetlabs-horizon code
# [secret_key]          secret key to encode cookies, …
# [cache_server_ip]     local memcached instance ip
# [cache_server_port]   local memcached instance port
# [horizon]             (bool) is horizon installed. Defaults to: true
# [swift]               (bool) is swift installed
# [quantum]             (bool) is quantum installed
#   The next is an array of arrays, that can be used to add call-out links to the dashboard for other apps.
#   There is no specific requirement for these apps to be for monitoring, that's just the defacto purpose.
#   Each app is defined in two parts, the display name, and the URI
# [horizon_app_links]     array as in '[ ["Nagios","http://nagios_addr:port/path"],["Ganglia","http://ganglia_addr"] ]'
# [enabled] Whether services should be enabled. This parameter can be used to
#   implement services in active-passive modes for HA. Optional. Defaults to true.
#
# === Examples
#
# class { 'openstack::controller':
#   public_address       => '192.168.0.3',
#   mysql_root_password  => 'changeme',
#   allowed_hosts        => ['127.0.0.%', '192.168.1.%'],
#   admin_email          => 'my_email@mw.com',
#   admin_password       => 'my_admin_password',
#   keystone_db_password => 'changeme',
#   keystone_admin_token => '12345',
#   glance_db_password   => 'changeme',
#   glance_user_password => 'changeme',
#   nova_db_password     => 'changeme',
#   nova_user_password   => 'changeme',
#   secret_key           => 'dummy_secret_key',
# }
#
class openstack::controller (
  # Required Network
  $public_address,
  $public_interface,
  $private_interface,
  $admin_email,
  # required password
  $admin_password,
  $rabbit_password,
  $keystone_db_password,
  $keystone_admin_token,
  $glance_db_password,
  $glance_user_password,
  $nova_db_password,
  $nova_user_password,
  $secret_key,
  # cinder and quantum password are not required b/c they are
  # optional. Not sure what to do about this.
  $cinder_user_password    = 'cinder_pass',
  $cinder_db_password      = 'cinder_pass',
  $quantum_user_password   = 'quantum_pass',
  $quantum_db_password     = 'quantum_pass',
  # Database
  $db_host                 = '127.0.0.1',
  $db_type                 = 'mysql',
  $mysql_root_password     = 'sql_pass',
  $mysql_account_security  = true,
  $mysql_bind_address      = '0.0.0.0',
  $allowed_hosts           = '%',
  # Keystone
  $keystone_db_user        = 'keystone',
  $keystone_db_dbname      = 'keystone',
  $keystone_admin_tenant   = 'admin',
  $region                  = 'RegionOne',
  # Glance
  $glance_db_user          = 'glance',
  $glance_db_dbname        = 'glance',
  $glance_api_servers      = undef,
  # Nova
  $nova_db_user            = 'nova',
  $nova_db_dbname          = 'nova',
  $purge_nova_config       = true,
  # Network
  $internal_address        = false,
  $admin_address           = false,
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $fixed_range             = '10.0.0.0/24',
  $floating_range          = false,
  $create_networks         = true,
  $num_networks            = 1,
  $multi_host              = false,
  $auto_assign_floating_ip = false,
  $network_config          = {},
  # Rabbit
  $rabbit_user             = 'nova',
  $rabbit_virtual_host     = '/',
  # Horizon
  $horizon                 = true,
  $cache_server_ip         = '127.0.0.1',
  $cache_server_port       = '11211',
  $horizon_app_links       = undef,
  $swift                   = false,
  # VNC
  $vnc_enabled             = true,
  # General
  $verbose                 = 'False',
  # cinder
  # if the cinder management components should be installed
  $cinder                  = true,
  $cinder_db_user          = 'cinder',
  $cinder_db_dbname        = 'cinder',
  # quantum
  $quantum                 = false,
  $quantum_db_user         = 'quantum',
  $quantum_db_dbname       = 'quantum',
  $enabled                 = true
) {

  if $internal_address {
    $internal_address_real = $internal_address
  } else {
    $internal_address_real = $public_address
  }
  if $admin_address {
    $admin_address_real = $admin_address
  } else {
    $admin_address_real = $internal_address_real
  }

  # Ensure things are run in order
  Class['openstack::db::mysql'] -> Class['openstack::keystone']
  Class['openstack::db::mysql'] -> Class['openstack::glance']
  Class['openstack::db::mysql'] -> Class['openstack::nova::controller']

  ####### DATABASE SETUP ######
  # set up mysql server
  if ($db_type == 'mysql') {
    if ($enabled) {
      Class['glance::db::mysql'] -> Class['glance::registry']
    }
    class { 'openstack::db::mysql':
      mysql_root_password    => $mysql_root_password,
      mysql_bind_address     => $mysql_bind_address,
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
    fail("Unsupported db : ${db_type}")
  }

  ####### KEYSTONE ###########
  class { 'openstack::keystone':
    verbose               => $verbose,
    db_type               => $db_type,
    db_host               => $db_host,
    db_password           => $keystone_db_password,
    db_name               => $keystone_db_dbname,
    db_user               => $keystone_db_user,
    admin_token           => $keystone_admin_token,
    admin_tenant          => $keystone_admin_tenant,
    admin_email           => $admin_email,
    admin_password        => $admin_password,
    public_address        => $public_address,
    internal_address      => $internal_address_real,
    admin_address         => $admin_address_real,
    region                => $region,
    glance_user_password  => $glance_user_password,
    nova_user_password    => $nova_user_password,
    cinder                => $cinder,
    cinder_user_password  => $cinder_user_password,
    quantum               => $quantum,
    quantum_user_password => $quantum_user_password,
    enabled               => $enabled,
  }


  ######## BEGIN GLANCE ##########
  class { 'openstack::glance':
    verbose                   => $verbose,
    db_type                   => $db_type,
    db_host                   => $db_host,
    glance_db_user            => $glance_db_user,
    glance_db_dbname          => $glance_db_dbname,
    glance_db_password        => $glance_db_password,
    glance_user_password      => $glance_user_password,
    enabled                   => $enabled,
  }

  ######## BEGIN NOVA ###########
  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }

  class { 'openstack::nova::controller':
    # Database
    db_host                 => $db_host,
    # Network
    network_manager         => $network_manager,
    network_config          => $network_config,
    floating_range          => $floating_range,
    fixed_range             => $fixed_range,
    public_address          => $public_address,
    admin_address           => $admin_address,
    internal_address        => $internal_address_real,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    create_networks         => $create_networks,
    num_networks            => $num_networks,
    multi_host              => $multi_host,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    # Quantum
    quantum                 => $quantum,
    quantum_user_password   => $quantum_user_password,
    quantum_db_password     => $quantum_db_password,
    quantum_db_user         => $quantum_db_user,
    quantum_db_dbname       => $quantum_db_dbname,
    # Nova
    nova_user_password      => $nova_user_password,
    nova_db_password        => $nova_db_password,
    nova_db_user            => $nova_db_user,
    nova_db_dbname          => $nova_db_dbname,
    # Rabbit
    rabbit_user             => $rabbit_user,
    rabbit_password         => $rabbit_password,
    rabbit_virtual_host     => $rabbit_virtual_host,
    # Glance
    glance_api_servers      => $glance_api_servers,
    # VNC
    vnc_enabled            => $vnc_enabled,
    # General
    verbose                 => $verbose,
    enabled                 => $enabled,
  }

  ######### Cinder Controller Services ########
  if ($cinder) {
    class { "cinder::base":
      verbose         => $verbose,
      sql_connection  => "mysql://${cinder_db_user}:${cinder_db_password}@${db_host}/${cinder_db_dbname}?charset=utf8",
      rabbit_password => $rabbit_password,
      rabbit_userid   => $rabbit_user,
    }

    class { 'cinder::api':
      keystone_password => $cinder_user_password,
    }

    class { 'cinder::scheduler': }
  } else {
    # Set up nova-volume
    class{ 'nova::volume': }
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
