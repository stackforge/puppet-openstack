#
# == Class: Parameters 
# 
# Convenient location to store default parameters.
# Able to be overridden in individual classes.
#
# === Parameters
#
# ==== General
#
# [enabled] 
#   - Whether services should be enabled. This parameter can be used to
#   implement services in active-passive modes for HA. Optional. 
#   - Defaults to true.
#
# [verbose]
#   - If the services should log verbosely. Optional.
#   - Defaults to false.
#
# [exported_resources]
#   - Whether or not to use exported resources
#   - Defautlts to true
#
# ==== Network
#
# [public_address]
#   - Public address used by vnchost. Optional.
#   - Defaults to ipaddress_eth0
#
# [public_interface]
#   - The interface used to route public traffic by the network service. Optional.
#   - Defaults to eth0
#
# [private_interface]
#   - The private interface used to bridge the VMs into a common network. Optional.
#   - Defaults to eth1
#
# [internal_address] 
#   - Internal address used for management. 
#   - Defaults to ipaddress_eth1
#
# [public_address]
# [admin_address]
#   - IP addresses for Keystone services
#   - default: ipaddress_eth0
#
# [floating_range]
#   - The floating ip range to be created. If it is false, then no floating ip range is created. Optional.
#   - Defaults to false.
#
# [fixed_range]
#   - The fixed private ip range to be created for the private VM network. Optional.
#   - Defaults to '10.0.0.0/24'.
#
# [network_manager]
#   - The network manager to use for the nova network service. Optional.
#   - Defaults to 'nova.network.manager.FlatDHCPManager'.
#
# [iscsi_ip_address]
#   - The IP address to use in the iscsi address
#   - Defaults to $internal_address
#
# [auto_assign_floating_ip]
#    - Rather configured to automatically allocate and assign a floating IP address to virtual instances when they are launched.
#    - Defaults to false.
#
# [network_config]
#    - Used to specify network manager specific parameters. Optional.
#    - Defualts to {}.
#
# [create_networks] 
#   - Rather network and floating ips should be created.
#   - Defaults to true
#
# [num_networks] 
#   - Number of networks that fixed range should be split into.
#   - Defaults to 1
#
# [multi_host] 
#   - Node should support multi-host networking mode for HA.
#   - Optional. Defaults to false.
#
#
# ==== Virtualization
#
# [libvirt_type]
#   - The virualization type being controlled by libvirt.  Optional.
#   - Defaults to 'kvm'.
#
# ==== Volumes
#
# [nova_volume]
#   - The name of the volume group to use for nova volume allocation. Optional.
#   - Defaults to 'nova-volumes'.
#
# [manage_volumes] 
#   - Rather nova-volume should be enabled on this compute node.
#   - Defaults to false.
#
# ==== Database
#
# [db_type]
#   - which type of database to use
#   - Defaults to 'mysql'
# 
# [db_host]
#   - where the db server is located
#   - default: 127.0.0.1
#
# [sql_connection] 
#   - SQL connection information.
#   - Defaults to false which indicates that exported resources will be used to determine connection information.
#
# ==== MySQL
#
# [mysql_root_password]
#    - The root password to set for the mysql database. Optional.
#    - Defaults to 'sql_pass'.
#
# [mysql_bind_address]
#   - address for mysql to listen on
#   - default: 0.0.0.0
#
# [mysql_account_security]
#   - whether to secure the mysql installation
#   - default: true
#
# [allowed_hosts]
#   - array of hosts that can access the mysql server
#   - default: ['127.0.0.1']
#
# ==== Rabbit
#
# [rabbit_password]
#    - The password to use for the rabbitmq user. Optional.
#    - Defaults to 'rabbit_pw'
#
# [rabbit_user]
#   - The rabbitmq user to use for auth. Optional.
#   - Defaults to 'nova'.
#
# [admin_email]
#   - The admin's email address. Optional.
#   - Defaults to 'root@localhost'
#
# [rabbit_host] 
#   - RabbitMQ host. False indicates it should be collected.
#   - Defaults to false which indicates that exported resources will be used to determine connection information.
#
# ==== Keystone
#
# [keystone_db_user]
#   - The name of the Keystone db user
#   - Defaults to 'keystone'
#
# [keystone_db_password]
#   - The default password for the keystone db user. Optional.
#   - Defaults to 'keystone_pass'.
#
# [keystone_db_dbname]
#   - The Keystone database name
#   - Defaults to 'keystone'
#
# [keystone_admin_tenant]
#   - The admin tenant name in Keystone
#   - Defaults to 'admin'
#
# [keystone_admin_token]
#   - The default auth token for keystone. Optional.
#   - Defaults to 'keystone_admin_token'.
#
# [admin_email]
#   - The email address for the Keystone admin user
#   - Defaults to 'root@localhost'
#
# [admin_password]
#   - The default password of the keystone admin. Optional.
#   - Defaults to 'ChangeMe'.
#
# ==== Nova
#
# [nova_db_user]
#   - The database user for Nova
#   - Defaults to 'nova'
#
# [nova_db_password]
#   - The nova db password. Optional.
#   - Defaults to 'nova_pass'.
#
# [nova_user_password]
#   - The password of the keystone user for the nova service. Optional.
#   - Defaults to 'nova_pass'.
#
# [nova_db_dbname]
#   - The database name for the Nova database
#   - Defaults to 'nova'
#
# [purge_nova_config]
#   - Whether unmanaged nova.conf entries should be purged. Optional.
#   - Defaults to true.
#
# ==== Glance
#
# [glance_db_user]
#   - The database user for Glance
#   - Defaults to 'glance'
#
# [glance_db_password]
#   - The password for the db user for glance. Optional.
#   - Defaults to 'glance_pass'.
#
# [glance_user_password]
#   - The password of the glance service user. Optional.
#   - Defaults to 'glance_pass'.
#
# [glance_db_dbname]
#   - The database name for the Glance database
#   - Defaults to 'glance'
#
# [glance_api_servers] 
#   - List of glance api servers of the form HOST:PORT
#   - Defaults to false which indicates that exported resources will be used to determine connection information.
#
# === Horizon related config - assumes puppetlabs-horizon code
#
# [secret_key]
#   - secret key to encode cookies,
#   - Defaults to 'dummy_secret_key'
#
# [cache_server_ip]
#   - local memcached instance ip
#   - Defaults to '127.0.0.1'
#
# [cache_server_port]
#   - local memcached instance port
#   - Defaults to '11211'
#
# [swift]
#   - (bool) is swift installed
#   - Defaults to false
#
# [quantum]
#   - (bool) is quantum installed
#   - Defaults to false
#
# [horizon_app_links]
#   - array as in '[ ["Nagios","http://nagios_addr:port/path"],["Ganglia","http://ganglia_addr"] ]'
#   - an array of arrays, that can be used to add call-out links to the dashboard for other apps.
#   - There is no specific requirement for these apps to be for monitoring, that's just the defacto purpose.
#   - Each app is defined in two parts, the display name, and the URI
#   - Defaults to false
#
# === VNC
#
# [vnc_enabled] 
#   - Rather vnc console should be enabled.
#   - Defaults to 'true',
#
# [vncserver_listen]
#   - The address on the compute node where VNC should listen
#   - Defaults to $internal_address
#
# [vncserver_proxyclient_address]
#   - The address where the controller should contact the vnc server on the compute node
#   - Defaults to $internal_address
#
# [vncproxy_host] 
#   - Host that serves as vnc proxy. This should be the public address of your controller.
#   - Defaults to $public_address
#

class openstack::params {

  # Generic
  $enabled            = true
  $verbose            = false
  $exported_resources = true

  # Network
  $public_address          = $::ipaddress_eth0
  $public_interface        = 'eth0'
  $internal_address        = $::ipaddress_eth1
  $admin_address           = $internal_address
  $private_interface       = 'eth2'
  $fixed_range             = '192.168.30.0/24'
  $floating_range          = false
  $network_manager         = 'nova.network.manager.FlatDHCPManager'
  $iscsi_ip_address        = $internal_address
  $auto_assign_floating_ip = false
  $network_config          = {}
  $create_networks         = true
  $num_networks            = 1
  $multi_host              = false

  # Virtualization
  $libvirt_type = 'qemu'

  # Volumes
  $nova_volume    = 'nova-volumes'
  $manage_volumes = false

  # Database
  $db_type           = 'mysql'
  $db_host           = $internal_address
  $sql_connection    = false

  # MySQL params
  $mysql_root_password    = 'sql_pass'
  $mysql_bind_address     = '0.0.0.0'
  $mysql_allowed_hosts    = ['127.0.0.%', '10.0.0.%']
  $mysql_account_security = true

  # Rabbit params
  $rabbit_password      = 'rabbit_pw'
  $rabbit_user          = 'nova'
  $rabbit_host          = false

  # Keystone params
  $keystone_db_user      = 'keystone'
  $keystone_db_password  = 'keystone_pass'
  $keystone_db_dbname    = 'keystone'
  $keystone_admin_tenant = 'admin'
  $keystone_admin_token  = 'keystone_admin_token'
  $admin_email           = 'root@localhost'
  $admin_password        = 'ChangeMe'

  # Glance params
  $glance_db_user       = 'glance'
  $glance_db_password   = 'glance_pass'
  $glance_user_password = 'glance_pass'
  $glance_db_dbname     = 'glance'
  $glance_api_servers   = "${public_address}:9292"

  # Nova params
  $nova_db_user            = 'nova'
  $nova_db_password        = 'nova_pass'
  $nova_user_password      = 'nova_pass'
  $nova_db_dbname          = 'nova'
  $purge_nova_config       = true

  # Horizon params
  $secret_key        = 'dummy_secret_key'
  $cache_server_ip   = '127.0.0.1'
  $cache_server_port = '11211'
  $swift             = false
  $quantum           = false
  $horizon_app_links = undef

  # vnc
  $vnc_enabled                   = true
  $vncserver_listen              = $internal_address
  $vncserver_proxyclient_address = $internal_address
  $vncproxy_host                 = $public_address

  # OS-specific params
  case $::osfamily {
    'Debian': {
    }
    'RedHat': {
    }
  }
}
