
#
# any nodes whose certname matches nova_all should
# become an openstack all-in-one node
#
#

Exec {
  logoutput => true,
}

resources { 'nova_config':
  purge => true,
}

node /openstack_all/ {

  class { 'openstack::all':
    public_address => $ipaddress_eth0
  }

  class { 'openstack_controller': }

}

node /openstack_controller/ {

  class { 'openstack::controller':
    public_address   => $public_hostname,
    internal_address => $ipaddress,
  }
  class { 'openstack_controller': }

}

node /openstack_compute/ {

  class { 'openstack::compute':
    # setting to qemu b/c I still test in ec2 :(
    internal_address => $ipaddress,
    libvirt_type     => 'qemu',
  }

}
# this shows an example of the code needed to perform
# an all in one installation

#
# sets up a few things that I use for testing
#
class openstack_controller {
  #
  # set up auth credntials so that we can authenticate easily
  #
  file { '/root/auth':
    content =>
  '
  export OS_TENANT_NAME=openstack
  export OS_USERNAME=admin
  export OS_PASSWORD=ChangeMe
  export OS_AUTH_URL="http://localhost:5000/v2.0/"
  '
  }
  # this is a hack that I have to do b/c openstack nova
  # sets up a route to reroute calls to the metadata server
  # to its own server which fails
  file { '/usr/lib/ruby/1.8/facter/ec2.rb':
    ensure => absent,
  }
}

