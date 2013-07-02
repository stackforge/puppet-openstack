# == Class: openstack::provision
#
# This class provides basic provisioning of a bare openstack
# deployment.  A non-admin user is created, an image is uploaded, and
# quantum networking is configured.  Once complete, it should be
# possible for the non-admin user to create a boot a VM that can be
# logged into via vnc (ssh may require extra configuration).
#
# This module is currently limited to targetting an all-in-one
# deployment for the following reasons:
#
#  - puppet-{keystone,glance,quantum} rely on their configuration files being
#    available on localhost which is not guaranteed for multi-host.
#
#  - the gateway configuration only supports a host that uses the same
#    interface for both management and tenant traffic.
#
#  - the gateway configuration makes the assumption that the local host is the
#    gateway host, which is not guaranteed to be true for multi-host.
#
# === Parameters
#
# Document parameters here.
#
# [*setup_ovs_bridge*]
#   Whether to configure the bridge specified by *public_bridge_name*
#   with the ip address of the subnet identified by
#   *public_subnet_name*.  This must be enabled if VMs are to be
#   reachable via floating ips.
#
# [*configure_tempest*]
#   Whether to use the provisioning details to configure Tempest, the
#   OpenStack integration test suite.
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
  # admin user
  $admin_username       = 'admin',
  $admin_password       = 'pass',
  $admin_tenant_name    = 'admin',

  ## Glance
  $image_name           = 'cirros',
  $image_source         = 'http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img',
  $image_ssh_user       = 'cirros',

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
  $configure_tempest    = false,
  $identity_uri         = undef,
  $tempest_clone_path   = '/var/lib/tempest',
  $tempest_clone_owner  = 'root',
  $setup_venv           = false,
) {
  ## Users

  keystone_tenant { $tenant_name:
    ensure      => present,
    enabled     => true,
    description => 'default tenant',
  }
  keystone_user { $username:
    ensure      => present,
    enabled     => true,
    tenant      => $tenant_name,
    password    => $password,
  }

  keystone_tenant { $alt_tenant_name:
    ensure      => present,
    enabled     => true,
    description => 'alt tenant',
  }
  keystone_user { $alt_username:
    ensure      => present,
    enabled     => true,
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
    router_external => true,
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
    # A quantum_router resource must explicitly declare a dependency on
    # the first subnet of the gateway network.
    require              => Quantum_subnet[$public_subnet_name],
  }
  quantum_router_interface { "${router_name}:${private_subnet_name}":
    ensure => present,
  }

  if $setup_ovs_bridge {
    quantum_l3_ovs_bridge { $public_bridge_name:
      ensure      => present,
      subnet_name => $public_subnet_name,
    }
  }

  ## Tempest

  if $configure_tempest {
    class { 'tempest':
      tempest_repo_uri    => $tempest_repo_uri,
      tempest_clone_path  => $tempest_clone_path,
      tempest_clone_owner => $tempest_clone_owner,
      setup_venv          => $setup_venv,
      image_name          => $image_name,
      image_name_alt      => $image_name,
      image_ssh_user      => $image_ssh_user,
      image_alt_ssh_user  => $image_ssh_user,
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
      public_network_name => $public_network_name,
      require             => [
                              Keystone_user[$username],
                              Keystone_user[$alt_username],
                              Glance_image[$image_name],
                              Quantum_network[$public_network_name],
                              ],
    }
  }

}
