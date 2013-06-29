#
# This class provides basic provisioning, ala devstack.
#
# For now, provisioning is only intended to work for an all-in-one deployment.
#
# Note that a quantum_router resource must declare a dependency on the
# first subnet of the gateway network.  Other dependencies for the
# quantum resources can be automatically determined.
#
class openstack::provision(
  ## Keystone
  # non admin user
  $username             = 'demo',
  $password             = 'pass',
  $tenant_name          = 'demo',
  # another non-admin user
  $alt_username         = 'alt_demo',
  $alt_password         = 'pass',
  $alt_tenant_name      = 'alt_demo',

  ## Glance
  $image_name           = 'cirros',
  $image_source         = 'http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img',

  ## Quantum
  $tenant_name          = 'demo',
  $public_network_name  = 'public',
  $public_subnet_name   = 'public_subnet',
  $floating_range       = '172.24.4.224/28',
  $private_network_name = 'private',
  $private_subnet_name  = 'private_subnet',
  $fixed_range          = '10.0.0.0/24',
  $router_name          = 'router1',
  $setup_ovs_bridge     = false,
  $public_bridge_name   = 'br-ex',

  ## Tempest
  $configure_tempest    = false
  $identity_uri         = undef,
  $tempest_clone_path   = '/var/lib/tempest',
  $tempest_clone_owner  = 'root',
) {
  ## Users

  keystone_tenant { $tenant_name:
    ensure      => present,
    enabled     => 'True',
    description => 'admin tenant',
  }
  keystone_user { $username:
    ensure      => present,
    enabled     => 'True',
    tenant      => $tenant_name,
    password    => $password,
  }

  keystone_tenant { $alt_tenant_name:
    ensure      => present,
    enabled     => 'True',
    description => 'alt tenant',
  }
  keystone_user { $alt_username:
    ensure      => present,
    enabled     => 'True',
    tenant      => $alt_tenant_name,
    password    => $alt_password,
  }

  ## Images

  glance_image { $image_name:
    ensure           => present,
    is_public        => 'yes',
    container_format => 'bare',
    disk_format      => 'qcow2',
    source           => $image_source,
  }

  ## Networks

  quantum_network { $public_network_name:
    ensure          => present,
    router_external => 'True',
    tenant_name     => $admin_tenant_name,
  }
  quantum_subnet { $public_subnet_name:
    ensure          => 'present',
    cidr            => $floating_range,
    network_name    => $public_network_name,
    tenant_name     => $admin_tenant_name,
  }
  quantum_network { $private_network_name:
    ensure      => present,
    tenant_name => $tenant_name,
  }
  quantum_subnet { $private_subnet_name:
    ensure       => present,
    cidr         => $fixed_range,
    network_name => $private_network_name,
    tenant_name  => $tenant_name,
  }
  # Tenant-owned router - assumes network namespace isolation
  quantum_router { $router_name:
    ensure               => present,
    tenant_name          => $tenant_name,
    gateway_network_name => $public_network_name,
    require              => Quantum_subnet[$public_subnet_name],
  }
  quantum_router_interface { "${router_name}:${private_subnet_name}":
    ensure => present,
  }

  if $setup_ovs_bridge {
    # TODO - need to ensure the gateway ip is added to br-ex and br-ex is brought up
    #  - Depend on Quantum_router[$router_name]
    #  - Use the port list trick from devstack to discover the private ip
  }
  
  ## Tempest

  if $configure_tempest {
    tempest {
      tempest_repo_uri    => $tempest_repo_uri,
      tempest_clone_path  => $tempest_clone_path,
      tempest_clone_owner => $tempest_clone_owner,
      image_name          => $image_name,
      identity_uri        => $identity_uri,
      username            => $username,
      password            => $password,
      tenant_name         => $tenant_name,
      alt_username        => $alt_username,
      alt_password        => $alt_password,
      alt_tenant_name     => $alt_tenant_name,
      admin_username      => $admin_username,
      admin_password      => $admin_password,
      admin_tenant_name   => $admin_tenant_name,
      quantum_available   => true,
      public_network_name => $public_network_name
      require             => [
                              Keystone_user[$username],
                              Keystone_user[$alt_username],
                              Glance_image[$image_name],
                              Quantum_network[$public_network_name],
                              ],
    }
  }

}
