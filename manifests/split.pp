#
# This manifest installs all of the nova
# components on one node.
#
resources { 'nova_config':
  purge => true,
}

# db settings
$db_password = 'password',
$db_name = 'nova',
$db_user = 'nova',
# this needs to be determined magically
$db_host = 'localhost',

# rabbit settings
$rabbit_password = 'rabbitpassword',
$rabbit_port = '5672',
$rabbit_userid = 'rabbit_user',
$rabbit_virtual_host = '/',
# this needs to be determined magically
$rabbit_host = 'localhost',

# glance settings
$image_service = 'nova.image.glance.GlanceImageService',
# this needs to be determined magically
$glance_host = 'localhost',
$glance_port = '9292',

# this is required for vagrant
$libvirt_type = 'qemu'

# bridge information
$flat_network_bridge  = 'br100',
$flat_network_bridge_ip  = '11.0.0.1',
$flat_network_bridge_netmask  = '255.255.255.0',

$admin_user   = 'nova_admin'
$project_name = 'nova_project'

# we need to be able to search for the following hosts:
# rabbit_host
# glance_host
# db_host
# api server

# initially going to install nova on one machine
node /nova/ {
  class { "nova":
    verbose             => $verbose,
    sql_connection      => "mysql://${db_user}:${db_password}@${db_host}/${db_name}",
    image_service       => $image_service,
    glance_host         => $glance_host,
    glance_port         => $glance_port,
    rabbit_host         => $rabbit_host,
    rabbit_port         => $rabbit_port,
    rabbit_userid       => $rabbit_userid,
    rabbit_password     => $rabbit_password,
    rabbit_virtual_host => $rabbit_virtual_host,
  }
  class { "nova::api": enabled => true }

  class { "nova::compute":
    api_server   => $ipaddress,
    libvirt_type => $libvirt_type,
    enabled      => true,
  }

  class { "nova::network::flat":
    enabled                     => true,
    flat_network_bridge         => $flat_network_bridge,
    flat_network_bridge_ip      => $flat_network_bridge_ip,
    flat_network_bridge_netmask => $flat_network_bridge_netmask,
  }
  nova::manage::admin { $admin_user: }
  nova::manage::project { $project_name:
    owner => $admin_user,
  }

  nova::manage::network { "${project_name}-net-${network}":
    network       => $nova_network,
    available_ips => $available_ips,
    require       => Nova::Manage::Project[$project_name],
  }
}

node /puppetmaster/ {

}

node /db/ {
  class { 'mysql::server': }
  class { 'nova::db':
    # pass in db config as params
    password => $db_password,
    name     => $db_name,
    user     => $db_user,
    host     => $db_host,
  }
}

node /rabbit/ {
  class { 'nova::rabbitmq':
    port         => $rabbit_port,
    userid       => $rabbit_userid,
    password     => $rabbit_password,
    virtual_host => $rabbit_virtual_host,
    require      => Host[$hostname],
  }
}

node /glance/ {
  # set up glance server
  class { 'glance::api':
    swift_store_user => 'foo_user',
    swift_store_key => 'foo_pass',
  }

  class { 'glance::registry': }

}
