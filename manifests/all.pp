#
# == Class: openstack::all
#
# Class that performs a basic openstack all in one installation.
#
# === Parameterrs
#
#  TODO public address should be optional.
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
#  [verbose] If the services should log verbosely. Optional. Defaults to false.
#  [purge_nova_config] Whether unmanaged nova.conf entries should be purged. Optional. Defaults to true.
#  [libvirt_type] The virualization type being controlled by libvirt.  Optional. Defaults to 'kvm'.
#  [nova_volume] The name of the volume group to use for nova volume allocation. Optional. Defaults to 'nova-volumes'.
#
# === Examples
#
#  class { 'openstack::all':
#    public_address       => '192.168.0.3',
#    public_interface     => eth0,
#    private_interface    => eth1,
#    admin_email          => my_email@mw.com,
#    admin_password       => 'my_admin_password',
#    libvirt_type         => 'kvm',
#  }
#
# === Authors
#
# Dan Bode <bodepd@gmail.com>
#
#
class openstack::all(
  # passing in the public ipaddress is required
  $public_address,
  $public_interface,
  $private_interface,
  $floating_range          = false,
  $fixed_range             = '10.0.0.0/24',
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $network_config          = {},
  # middleware credentials
  $mysql_root_password     = 'sql_pass',
  $rabbit_password         = 'rabbit_pw',
  $rabbit_user             = 'nova',
  # opestack credentials
  $admin_email             = 'someuser@some_fake_email_address.foo',
  $admin_password          = 'ChangeMe',
  $keystone_db_password    = 'keystone_pass',
  $keystone_admin_token    = 'keystone_admin_token',
  $nova_db_password        = 'nova_pass',
  $nova_user_password      = 'nova_pass',
  $glance_db_password      = 'glance_pass',
  $glance_user_password    = 'glance_pass',
  # config
  $verbose                 = false,
  $auto_assign_floating_ip = false,
  $purge_nova_config       = true,
  $libvirt_type            = 'kvm',
  $nova_volume             = 'nova-volumes'
) {


  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }

  # set up mysql server
  class { 'mysql::server':
    config_hash => {
      # the priv grant fails on precise if I set a root password
      # 'root_password' => $mysql_root_password,
      'bind_address'  => '127.0.0.1'
    }
  }

  ####### KEYSTONE ###########

  # set up keystone database
  class { 'keystone::db::mysql':
    password => $keystone_db_password,
  }
  # set up the keystone config for mysql
  class { 'keystone::config::mysql':
    password => $keystone_db_password,
  }
  # set up keystone
  class { 'keystone':
    admin_token  => $keystone_admin_token,
    bind_host    => '127.0.0.1',
    log_verbose  => $verbose,
    log_debug    => $verbose,
    catalog_type => 'sql',
  }
  # set up keystone admin users
  class { 'keystone::roles::admin':
    email    => $admin_email,
    password => $admin_password,
  }
  # set up the keystone service and endpoint
  class { 'keystone::endpoint': }

  ######## END KEYSTONE ##########

  ######## BEGIN GLANCE ##########

  # set up keystone user, endpoint, service
  class { 'glance::keystone::auth':
    password => $glance_user_password,
    public_address => $public_address,
  }

  # creat glance db/user/grants
  class { 'glance::db::mysql':
    host     => '127.0.0.1',
    password => $glance_db_password,
  }

  # configure glance api
  class { 'glance::api':
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    auth_host         => '127.0.0.1',
    auth_port         => '35357',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
  }

  # configure glance to store images to disk
  class { 'glance::backend::file': }

  class { 'glance::registry':
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    auth_host         => '127.0.0.1',
    auth_port         => '35357',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    sql_connection    => "mysql://glance:${glance_db_password}@127.0.0.1/glance",
  }


  ######## END GLANCE ###########

  ######## BEGIN NOVA ###########

  class { 'nova::keystone::auth':
    password => $nova_user_password,
    public_address => $public_address,
  }

  class { 'nova::rabbitmq':
    userid   => $rabbit_user,
    password => $rabbit_password,
  }

  class { 'nova::db::mysql':
    password => $nova_db_password,
    host     => 'localhost',
  }

  class { 'nova':
    sql_connection     => "mysql://nova:${nova_db_password}@localhost/nova",
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => '127.0.0.1:9292',
    verbose            => $verbose,
  }

  class { 'nova::api':
    enabled        => true,
    admin_password => $nova_user_password,
  }

  # set up networking
  class { 'nova::network':
    private_interface => $private_interface,
    public_interface  => $public_interface,
    fixed_range       => $fixed_range,
    floating_range    => $floating_range,
    install_service   => true,
    enabled           => true,
    network_manager   => $network_manager,
    config_overrides  => $network_config,
    create_networks   => true,
  }

  if $auto_assign_floating_ip {
    nova_config { 'auto_assign_floating_ip':   value => 'True'; }
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::volume',
    'nova::cert',
    'nova::consoleauth'
  ]:
    enabled => true
  }

  class { 'nova::vncproxy':
    enabled => true,
    host    => $public_hostname,
  }

  class { 'nova::compute':
    enabled                       => true,
    vnc_enabled                   => true,
    vncserver_proxyclient_address => '127.0.0.1',
    vncproxy_host                 => $public_address,
  }

  class { 'nova::compute::libvirt':
    libvirt_type     => $libvirt_type,
    vncserver_listen => '127.0.0.1',
  }

  class { 'nova::volume::iscsi':
    volume_group     => $nova_volume,
    iscsi_ip_address => '127.0.0.1',
  }

#  nova::network::bridge { 'br100':
#    ip      => '11.0.0.1',
#    netmask => '255.255.255.0',
#  }

  ######## Horizon ########

  class { 'memcached':
    listen_ip => '127.0.0.1',
  }

  class { 'horizon': }

  ######## End Horizon #####

}
